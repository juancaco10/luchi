<?php
/**
 * Upload Routes — POST /uploads/sighting-photo
 *
 * Terreno nuevo: es la primera subida de archivos del backend. Por eso el
 * orden de las comprobaciones importa tanto como el resultado:
 *   1. requireAuth() — nadie sube nada sin sesión.
 *   2. Tamaño y error de subida.
 *   3. Tipo real del fichero vía finfo (nunca el `type`/nombre que manda
 *      el cliente — eso es trivialmente falsificable).
 *   4. Re-codificar con GD: esto hace dos cosas a la vez —
 *      (a) borra TODO el EXIF (incluida la ubicación GPS de precisión
 *          completa que el propio dispositivo pudo incrustar), que es un
 *          requisito de docs/PRIVACY.md antes de cualquier release;
 *      (b) confirma que el fichero es una imagen real decodificable y no
 *          un script disfrazado con extensión de imagen.
 *   5. Nombre de fichero aleatorio — nunca el nombre que trae el cliente.
 *
 * La carpeta backend/api/uploads/ tiene su propio .htaccess que bloquea
 * la ejecución de cualquier script, como segunda capa de defensa.
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/auth.php';

const MAX_UPLOAD_BYTES = 5 * 1024 * 1024; // 5 MB
const MAX_UPLOAD_DIMENSION = 1600; // px, lado mayor

if ($method === 'POST' && $path === '/uploads/sighting-photo') {
    $user = requireAuth();

    if (!isset($_FILES['photo'])) {
        jsonError('No se recibió ninguna foto', 400);
    }

    $file = $_FILES['photo'];

    if ($file['error'] !== UPLOAD_ERR_OK) {
        jsonError('Error al subir la foto', 400);
    }

    if ($file['size'] > MAX_UPLOAD_BYTES) {
        jsonError('La foto es demasiado grande (máx. 5 MB)', 400);
    }

    // Tipo real del contenido, no la extensión ni el `Content-Type` que
    // manda el cliente — ambos son trivialmente falsificables.
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mime  = finfo_file($finfo, $file['tmp_name']);
    finfo_close($finfo);

    $allowed = ['image/jpeg', 'image/png', 'image/webp'];
    if (!in_array($mime, $allowed, true)) {
        jsonError('Formato no soportado. Usa JPG, PNG o WEBP.', 400);
    }

    // Decodificar y volver a codificar: esto elimina todos los metadatos
    // EXIF (ubicación, dispositivo) y sirve de segunda validación — si el
    // fichero no es realmente una imagen, estas funciones devuelven false.
    $source = match ($mime) {
        'image/jpeg' => @imagecreatefromjpeg($file['tmp_name']),
        'image/png'  => @imagecreatefrompng($file['tmp_name']),
        'image/webp' => @imagecreatefromwebp($file['tmp_name']),
        default      => false,
    };

    if ($source === false) {
        jsonError('El archivo no es una imagen válida', 400);
    }

    $width  = imagesx($source);
    $height = imagesy($source);
    $maxSide = max($width, $height);

    if ($maxSide > MAX_UPLOAD_DIMENSION) {
        $scale     = MAX_UPLOAD_DIMENSION / $maxSide;
        $newWidth  = (int) round($width * $scale);
        $newHeight = (int) round($height * $scale);

        $resized = imagecreatetruecolor($newWidth, $newHeight);
        imagecopyresampled(
            $resized, $source,
            0, 0, 0, 0,
            $newWidth, $newHeight, $width, $height
        );
        imagedestroy($source);
        $source = $resized;
    }

    $uploadsDir = __DIR__ . '/../uploads/sightings';
    if (!is_dir($uploadsDir)) {
        mkdir($uploadsDir, 0755, true);
    }

    $filename = bin2hex(random_bytes(16)) . '.jpg';
    $destPath = $uploadsDir . '/' . $filename;

    // Siempre se guarda re-codificado como JPEG, sin importar el formato
    // de entrada — un único formato de salida simplifica todo lo demás.
    $saved = imagejpeg($source, $destPath, 85);
    imagedestroy($source);

    if (!$saved) {
        jsonError('No se pudo guardar la foto', 500);
    }

    // URL pública absoluta: el dominio + el directorio donde vive este
    // index.php (normalmente /api), + uploads/sightings/<archivo>.
    $scheme     = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host       = $_SERVER['HTTP_HOST'] ?? 'localhost';
    $scriptDir  = rtrim(str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? '')), '/');
    $photoUrl   = "{$scheme}://{$host}{$scriptDir}/uploads/sightings/{$filename}";

    jsonResponse(['success' => true, 'photo_url' => $photoUrl], 201);
}
