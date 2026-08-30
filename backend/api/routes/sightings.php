<?php
/**
 * Sighting Routes — POST /sightings, GET /sightings, GET /my-sightings,
 * PUT /sightings/{id}, POST /sightings/{id}/archive,
 * POST|DELETE /sightings/{id}/like, POST /sightings/{id}/moderate,
 * GET /moderation/queue
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../lib/gamification.php';
require_once __DIR__ . '/../lib/media.php';

// ── Helpers de privacidad ─────────────────────────────────────────
// El feed comunitario expone contenido de menores a otros menores. Estas
// dos funciones son la segunda capa de defensa exigida por
// docs/PRIVACY.md: aunque el cliente ya difumine las coordenadas antes de
// enviarlas, el servidor no se fía y vuelve a recortar al salir.

/** Redondea a 3 decimales (~100 m). Nunca devolver precisión completa. */
function blurCoord(mixed $value): float
{
    return round((float) $value, 3);
}

/**
 * Recorta `location_name` a nivel ciudad (lo anterior a la primera coma).
 * Un nombre geocodificado completo puede llegar a incluir calle y número.
 */
function cityLevelLocation(?string $name): ?string
{
    if ($name === null || trim($name) === '') return null;
    $parts = explode(',', $name);
    return trim($parts[0]) ?: null;
}

/**
 * Fecha en ISO-8601 UTC.
 *
 * MySQL devuelve `2026-08-06 21:03:11` sin zona horaria, y el cliente
 * (`DateTime.tryParse` en Dart) lo interpreta como hora **local del
 * teléfono** — así que el "hace 3 horas" se desviaba tanto como el offset
 * entre el servidor y el usuario. Emitir siempre con zona explícita lo
 * arregla en origen para todos los consumidores.
 */
function isoUtc(?string $mysqlDatetime): ?string
{
    if ($mysqlDatetime === null || $mysqlDatetime === '') return null;
    $ts = strtotime($mysqlDatetime);
    return $ts === false ? null : gmdate('Y-m-d\TH:i:s\Z', $ts);
}

/** Safe Launch defaults to private sightings until moderation is operated. */
function publicSightingsEnabled(): bool
{
    return defined('PUBLIC_SIGHTINGS_ENABLED') && PUBLIC_SIGHTINGS_ENABLED === true;
}

/**
 * Returns a server-owned upload filename only when it belongs to this user
 * and is unclaimed (or already attached to the sighting being edited).
 */
function ownedSightingUpload(PDO $db, int $userId, ?string $photoUrl, ?int $sightingId): ?string
{
    if ($photoUrl === null || $photoUrl === '') return null;

    $path = parse_url($photoUrl, PHP_URL_PATH);
    $filename = is_string($path) ? basename($path) : '';
    if (!preg_match('/^[a-f0-9]{32}\\.jpg$/', $filename)) {
        jsonError('La foto debe provenir de una subida autorizada');
    }

    $stmt = $db->prepare(
        'SELECT filename FROM sighting_photo_uploads
          WHERE user_id = ? AND filename = ?
            AND (attached_sighting_id IS NULL OR attached_sighting_id = ?)'
    );
    $stmt->execute([$userId, $filename, $sightingId]);
    if (!$stmt->fetchColumn()) {
        jsonError('La foto no existe o no pertenece a esta cuenta', 403);
    }

    return $filename;
}

/** Recalcula `likes_count` desde la tabla de verdad. */
function refreshLikesCount(PDO $db, int $sightingId): int
{
    $stmt = $db->prepare('SELECT COUNT(*) FROM sighting_likes WHERE sighting_id = ?');
    $stmt->execute([$sightingId]);
    $count = (int) $stmt->fetchColumn();

    $db->prepare('UPDATE sightings SET likes_count = ? WHERE id = ?')
       ->execute([$count, $sightingId]);

    return $count;
}

// ── POST /sighting ────────────────────────────────────────────────

if ($method === 'POST' && $path === '/sightings') {
    $user = requireAuth();
    $body = json_decode(file_get_contents('php://input'), true) ?? [];

    $lat          = filter_var($body['lat'] ?? null, FILTER_VALIDATE_FLOAT);
    $lng          = filter_var($body['lng'] ?? null, FILTER_VALIDATE_FLOAT);
    $quantity     = (int) ($body['quantity'] ?? 1);
    $notes        = sanitize($body['notes']         ?? '');
    $photoUrl     = sanitize($body['photo_url']     ?? '');
    $locationName = sanitize($body['location_name'] ?? '');

    // Validate
    if ($lat === false || $lat === null || $lat < -90  || $lat > 90) {
        jsonError('Latitud inválida');
    }
    if ($lng === false || $lng === null || $lng < -180 || $lng > 180) {
        jsonError('Longitud inválida');
    }
    if ($quantity < 1 || $quantity > 10000) {
        jsonError('Cantidad inválida (1–10000)');
    }

    if (mb_strlen($notes) > 280) {
        jsonError('Las notas no pueden superar 280 caracteres');
    }

    $db = getDB();
    $photoFilename = ownedSightingUpload($db, (int) $user['id'], $photoUrl ?: null, null);
    // Nunca confiar en la URL del cliente: el servidor siempre reconstruye
    // la URL pública a partir del filename ya validado como propio.
    $photoUrl = $photoFilename !== null ? sightingPhotoUrl($photoFilename) : null;

    // Auto-publicación (decisión de producto para una app familiar): todo
    // avistamiento nace aprobado y se ve para todos al instante. Si algún
    // día se vuelve a exigir moderación manual, quitar estas dos columnas
    // del INSERT y restaurar la condición 1 del GET /sightings.
    //
    // Todo esto es una sola unidad: crear el avistamiento, reclamar la
    // foto y otorgar puntos/nivel/insignias. Sin transacción, un fallo a
    // mitad (p. ej. `syncUserProgress`) dejaría el avistamiento guardado
    // sin sus puntos, o puntos otorgados sin avistamiento — un rollback
    // limpio es más seguro que dejar ese estado a medias.
    $db->beginTransaction();
    try {
        // Regresión detectada en auditoría: esto decía "pending", lo que
        // dejaba todo avistamiento invisible para el resto para siempre
        // (nada vuelve a aprobarlo), contradiciendo la auto-publicación
        // descrita arriba y el filtro de GET /sightings más abajo.
        $stmt = $db->prepare(
            'INSERT INTO sightings
                (user_id, lat, lng, quantity, notes, photo_url, location_name,
                 moderation_status, moderated_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, "approved", NOW())'
        );
        $stmt->execute([
            $user['id'],
            $lat,
            $lng,
            $quantity,
            $notes ?: null,
            $photoUrl ?: null,
            $locationName ?: null,
        ]);

        $sightingId = (int) $db->lastInsertId();
        if ($photoFilename !== null) {
            $db->prepare(
                'UPDATE sighting_photo_uploads SET attached_sighting_id = ? WHERE filename = ? AND user_id = ?'
            )->execute([$sightingId, $photoFilename, $user['id']]);
        }

        // Award points
        $pts = 20; // AppConstants.pointsSighting
        $db->prepare('UPDATE users SET points = points + ? WHERE id = ?')
           ->execute([$pts, $user['id']]);

        // Re-read points, then sync level and badges (lib/gamification.php).
        $totalPoints = syncUserProgress($db, (int) $user['id']);

        $db->commit();
    } catch (Throwable $e) {
        $db->rollBack();
        jsonError('No se pudo registrar el avistamiento', 500);
    }

    jsonResponse([
        'success'       => true,
        'sighting_id'   => $sightingId,
        'points_earned' => $pts,
        'total_points'  => $totalPoints,
        'level'         => getLevelForPoints($totalPoints),
        'level_name'    => getLevelName($totalPoints),
    ], 201);
}

// ── GET /sightings — feed comunitario ─────────────────────────────
//
// Estuvo devolviendo 410 a propósito durante toda la v1: exponer
// coordenadas y fotos de menores sin sistema comunitario era un riesgo
// real. Se abre ahora, y sigue siendo seguro **solo** por estas tres
// condiciones — si se quita cualquiera, hay que volver a cerrarlo:
//
//   1. `author_name` y `author_avatar` identifican al autor (decisión de
//      producto, ver docs/PRIVACY.md). El avatar que sale es la foto
//      elegida por el propio usuario (Google o avatar predefinido).
//   2. Las coordenadas se redondean aquí también, no solo en el cliente.
//   3. `location_name` se recorta a nivel ciudad.
//
// La moderación previa (condición 4 de la versión original: "lo ajeno solo
// se devuelve aprobado por un moderador") se sustituyó por auto-publicación
// por decisión de producto: todo avistamiento nace `approved` (ver
// POST /sightings) y se ve para todos al instante, sin cola de revisión.
// Si algún día se restaura la moderación manual, hay que (a) volver a
// poner la condición de filtrado por `moderation_status` y (b) quitar el
// `approved` del INSERT. La excepción de "lo propio pendiente" del WHERE
// se conserva para no dejar huérfanos los avistamientos viejos que aún
// estén en 'pending' — nadie más los ve hasta que se aprueben.
//
// `is_mine` se calcula en el servidor y le dice a la app si el post es
// propio — para mostrar la foto/avatar con la misma lógica en todos los
// casos, tanto en lo propio como en lo ajeno.

if ($method === 'GET' && $path === '/sightings') {
    if (!publicSightingsEnabled()) {
        jsonError('La comunidad no está disponible en esta versión', 403);
    }
    $user  = requireAuth();
    $db    = getDB();

    $limit  = min(50, max(1, (int) ($_GET['limit']  ?? 30)));
    $offset = max(0, (int) ($_GET['offset'] ?? 0));

    $stmt = $db->prepare(
        'SELECT s.id, s.user_id, s.lat, s.lng, s.quantity, s.notes,
                s.photo_url, s.location_name, s.created_at, s.likes_count,
                s.moderation_status,
                u.name AS author_name, u.nickname AS author_nickname,
                u.avatar_url AS author_avatar,
                (l.id IS NOT NULL) AS liked_by_me
           FROM sightings s
           LEFT JOIN users u ON u.id = s.user_id
           LEFT JOIN sighting_likes l
             ON l.sighting_id = s.id AND l.user_id = ?
          WHERE s.archived_at IS NULL
            AND (s.moderation_status = "approved"
                 OR (s.user_id = ? AND s.moderation_status = "pending"))
          ORDER BY s.created_at DESC
          LIMIT ' . $limit . ' OFFSET ' . $offset
    );
    // `:me` aparece dos veces en el SQL; con PDO::ATTR_EMULATE_PREPARES
    // desactivado (config/database.php) repetir un parámetro nombrado
    // lanza HY093 — por eso se usan `?` posicionales. `limit`/`offset` se
    // interpolaron a propósito: ya son enteros validados arriba.
    $stmt->execute([$user['id'], $user['id']]);
    $rows = $stmt->fetchAll();

    jsonResponse([
        'sightings' => array_map(fn($s) => [
            'id'            => (int) ($s['id'] ?? 0),
            'lat'           => blurCoord($s['lat'] ?? 0),
            'lng'           => blurCoord($s['lng'] ?? 0),
            'quantity'      => (int) ($s['quantity'] ?? 1),
            'notes'         => $s['notes'] ?? null,
            'photo_url'     => $s['photo_url'] ?? null,
            'location_name' => cityLevelLocation($s['location_name'] ?? null),
            'created_at'    => isoUtc($s['created_at'] ?? null),
            'likes_count'   => (int) ($s['likes_count'] ?? 0),
            'liked_by_me'   => (bool) ($s['liked_by_me'] ?? false),
            'is_mine'       => ((int) ($s['user_id'] ?? 0)) === ((int) ($user['id'] ?? 0)),
            // Solo lo propio pendiente llega aquí con true; lo ajeno siempre
            // está aprobado (lo impone el WHERE de arriba).
            'is_pending'    => ($s['moderation_status'] ?? 'pending') !== 'approved',
            // Autor visible por decisión de producto (docs/PRIVACY.md).
            // El nombre completo del autor NO se manda: solo el apodo
            // elegido por el usuario (si lo tiene) o su primer nombre,
            // que es lo único que muestra la app.
            'author_name'   => !empty($s['author_nickname'])
                ? $s['author_nickname']
                : (ucfirst(strtok((string) ($s['author_name'] ?? ''), ' ')) ?: null),
            'author_avatar' => $s['author_avatar'] ?? null,
            // Deliberadamente ausentes: user_id, updated_at.
        ], $rows),
    ]);
}

// ── POST|DELETE /sightings/{id}/like ──────────────────────────────
// Un corazón por persona: lo impone el UNIQUE KEY de sighting_likes, así
// que un doble toque (o dos peticiones en carrera) no puede contar dos
// veces. `likes_count` se recalcula desde la tabla dentro de la misma
// transacción, nunca con `likes_count + 1`, que sí podría desviarse.

if (preg_match('#^/sightings/(\d+)/like$#', $path, $m)
    && in_array($method, ['POST', 'DELETE'], true)) {
    $user       = requireAuth();
    $sightingId = (int) $m[1];
    $db         = getDB();

    // Solo se puede dar corazón a algo que esté realmente publicado. Sin
    // esto se podría "likear" un avistamiento pendiente o rechazado
    // adivinando su id, y descubrir así que existe.
    $check = $db->prepare(
        'SELECT 1 FROM sightings
          WHERE id = ? AND moderation_status = "approved" AND archived_at IS NULL'
    );
    $check->execute([$sightingId]);
    if (!$check->fetchColumn()) {
        jsonError('Avistamiento no encontrado', 404);
    }

    $db->beginTransaction();
    try {
        if ($method === 'POST') {
            $db->prepare(
                'INSERT IGNORE INTO sighting_likes (sighting_id, user_id) VALUES (?, ?)'
            )->execute([$sightingId, $user['id']]);
        } else {
            $db->prepare(
                'DELETE FROM sighting_likes WHERE sighting_id = ? AND user_id = ?'
            )->execute([$sightingId, $user['id']]);
        }

        $count = refreshLikesCount($db, $sightingId);
        $db->commit();
    } catch (Throwable $e) {
        $db->rollBack();
        jsonError('No se pudo registrar el corazón', 500);
    }

    jsonResponse([
        'success'     => true,
        'likes_count' => $count,
        'liked'       => $method === 'POST',
    ]);
}

// ── GET /my-sightings ─────────────────────────────────────────────
// ?archived=1 pide los archivados; por defecto solo los activos.

if ($method === 'GET' && $path === '/my-sightings') {
    $user           = requireAuth();
    $db             = getDB();
    $wantArchived   = ($_GET['archived'] ?? '') === '1';

    // Aquí sí se devuelven las coordenadas tal cual y el nombre completo
    // del lugar: es contenido propio, mostrándoselo a su propio autor. El
    // recorte por privacidad aplica a lo que ven *otros* (GET /sightings).
    $stmt = $db->prepare(
        'SELECT s.*, (l.id IS NOT NULL) AS liked_by_me
           FROM sightings s
           LEFT JOIN sighting_likes l
             ON l.sighting_id = s.id AND l.user_id = ?
          WHERE s.user_id = ?
            AND s.archived_at IS ' . ($wantArchived ? 'NOT NULL' : 'NULL') . '
          ORDER BY s.created_at DESC LIMIT 100'
    );
    // Mismo caso que en el feed: `:me` repetido con prepares nativos
    // lanza HY093, así que se usa `?` posicional (ver GET /sightings).
    $stmt->execute([$user['id'], $user['id']]);
    $sightings = $stmt->fetchAll();

    jsonResponse([
        'sightings' => array_map(fn($s) => [
            'id'            => (int) ($s['id'] ?? 0),
            'lat'           => (float) ($s['lat'] ?? 0),
            'lng'           => (float) ($s['lng'] ?? 0),
            'quantity'      => (int) ($s['quantity'] ?? 1),
            'notes'         => $s['notes'] ?? null,
            'photo_url'     => $s['photo_url'] ?? null,
            'location_name' => $s['location_name'] ?? null,
            'created_at'    => isoUtc($s['created_at'] ?? null),
            'updated_at'    => isoUtc($s['updated_at'] ?? null),
            'archived_at'   => isoUtc($s['archived_at'] ?? null),
            'is_pending'    => false,
            'likes_count'   => (int) ($s['likes_count'] ?? 0),
            'liked_by_me'   => (bool) ($s['liked_by_me'] ?? false),
            'is_mine'       => true,
            // El autor sí ve en qué estado de moderación está lo suyo:
            // saber por qué algo propio aún no aparece en el feed no es
            // una fuga, es la explicación que merece.
            'moderation_status' => $s['moderation_status'] ?? 'pending',
        ], $sightings),
    ]);
}

// ── PUT /sightings/{id} — editar ────────────────────────────────────
// No otorga puntos: editar no es un logro nuevo.

if ($method === 'PUT' && preg_match('#^/sightings/(\d+)$#', $path, $m)) {
    $user       = requireAuth();
    $sightingId = (int) $m[1];
    $body       = json_decode(file_get_contents('php://input'), true) ?? [];

    $lat          = filter_var($body['lat'] ?? null, FILTER_VALIDATE_FLOAT);
    $lng          = filter_var($body['lng'] ?? null, FILTER_VALIDATE_FLOAT);
    $quantity     = (int) ($body['quantity'] ?? 1);
    $notes        = sanitize($body['notes']         ?? '');
    $photoUrl     = sanitize($body['photo_url']     ?? '');
    $locationName = sanitize($body['location_name'] ?? '');

    if ($lat === false || $lat === null || $lat < -90  || $lat > 90) {
        jsonError('Latitud inválida');
    }
    if ($lng === false || $lng === null || $lng < -180 || $lng > 180) {
        jsonError('Longitud inválida');
    }
    if ($quantity < 1 || $quantity > 10000) {
        jsonError('Cantidad inválida (1–10000)');
    }

    if (mb_strlen($notes) > 280) {
        jsonError('Las notas no pueden superar 280 caracteres');
    }

    $db = getDB();

    // Comprobación de propiedad aparte del UPDATE: `rowCount()` de un
    // UPDATE solo cuenta filas que cambiaron de verdad (PDO/MySQL sin
    // MYSQL_ATTR_FOUND_ROWS), así que guardar sin modificar ningún campo
    // daría 0 filas afectadas y un 404 falso aunque el avistamiento sí
    // exista y sea del usuario.
    $owns = $db->prepare('SELECT photo_url FROM sightings WHERE id = ? AND user_id = ?');
    $owns->execute([$sightingId, $user['id']]);
    $existingPhotoUrl = $owns->fetchColumn();
    if ($existingPhotoUrl === false) {
        // O no existe, o no es del usuario autenticado — mismo mensaje en
        // ambos casos para no filtrar si el id pertenece a otra cuenta.
        jsonError('Avistamiento no encontrado', 404);
    }

    $photoFilename = ownedSightingUpload(
        $db,
        (int) $user['id'],
        $photoUrl ?: null,
        $sightingId,
    );
    // Nunca confiar en la URL del cliente: el servidor siempre reconstruye
    // la URL pública a partir del filename ya validado como propio.
    $photoUrl = $photoFilename !== null ? sightingPhotoUrl($photoFilename) : null;

    // Con auto-publicación el contenido ya está visible para todos al
    // editar; no hay nada que "reabrir" para revisión.
    $stmt = $db->prepare(
        'UPDATE sightings
         SET lat = ?, lng = ?, quantity = ?, notes = ?, photo_url = ?, location_name = ?
         WHERE id = ? AND user_id = ?'
    );
    $stmt->execute([
        $lat,
        $lng,
        $quantity,
        $notes ?: null,
        $photoUrl ?: null,
        $locationName ?: null,
        $sightingId,
        $user['id'],
    ]);

    if ($existingPhotoUrl !== ($photoUrl ?: null)) {
        $db->prepare(
            'UPDATE sighting_photo_uploads SET attached_sighting_id = NULL WHERE attached_sighting_id = ?'
        )->execute([$sightingId]);
        if ($photoFilename !== null) {
            $db->prepare(
                'UPDATE sighting_photo_uploads SET attached_sighting_id = ? WHERE filename = ? AND user_id = ?'
            )->execute([$sightingId, $photoFilename, $user['id']]);
        }
    }

    jsonResponse(['success' => true]);
}

// ── GET /moderation/queue ──────────────────────────────────────────
// Lo pendiente de revisar. Solo backend/admin/moderation.php lo consume.

if ($method === 'GET' && $path === '/moderation/queue') {
    $user = requireAuth();
    if (!$user['is_moderator']) {
        jsonError('No autorizado', 403);
    }

    $db   = getDB();
    $stmt = $db->query(
        'SELECT s.id, s.quantity, s.notes, s.photo_url, s.location_name,
                s.created_at, u.name AS author_name, u.email AS author_email
           FROM sightings s
           JOIN users u ON u.id = s.user_id
          WHERE s.moderation_status = "pending"
          ORDER BY s.created_at ASC
          LIMIT 100'
    );

    jsonResponse(['sightings' => $stmt->fetchAll()]);
}

// ── POST /sightings/{id}/moderate — aprobar o rechazar ─────────────
// body: {"status": "approved" | "rejected"}

if ($method === 'POST' && preg_match('#^/sightings/(\d+)/moderate$#', $path, $m)) {
    $user = requireAuth();
    if (!$user['is_moderator']) {
        jsonError('No autorizado', 403);
    }

    $sightingId = (int) $m[1];
    $body       = json_decode(file_get_contents('php://input'), true) ?? [];
    $status     = $body['status'] ?? '';

    if (!in_array($status, ['approved', 'rejected'], true)) {
        jsonError('status debe ser "approved" o "rejected"');
    }

    $db   = getDB();
    $stmt = $db->prepare(
        'UPDATE sightings SET moderation_status = ?, moderated_at = NOW() WHERE id = ?'
    );
    $stmt->execute([$status, $sightingId]);

    if ($stmt->rowCount() === 0) {
        jsonError('Avistamiento no encontrado', 404);
    }

    jsonResponse(['success' => true, 'status' => $status]);
}

// ── POST /sightings/{id}/archive — archivar o desarchivar ──────────
// Un solo endpoint para ambos sentidos; body: {"archived": true|false}.
// No borra la fila: los puntos otorgados al crear nunca se restan, así
// que un borrado real permitiría farmear puntos con crear→borrar→crear.

if ($method === 'POST' && preg_match('#^/sightings/(\d+)/archive$#', $path, $m)) {
    $user       = requireAuth();
    $sightingId = (int) $m[1];
    $body       = json_decode(file_get_contents('php://input'), true) ?? [];
    $archived   = (bool) ($body['archived'] ?? true);

    $db = getDB();

    // Ownership check aparte del UPDATE: desarchivar algo ya activo (o
    // archivar algo ya archivado en el mismo segundo) es un no-op para
    // MySQL y rowCount() daría 0 aunque el avistamiento sí exista.
    $owns = $db->prepare('SELECT 1 FROM sightings WHERE id = ? AND user_id = ?');
    $owns->execute([$sightingId, $user['id']]);
    if (!$owns->fetchColumn()) {
        jsonError('Avistamiento no encontrado', 404);
    }

    $stmt = $db->prepare(
        'UPDATE sightings SET archived_at = ? WHERE id = ? AND user_id = ?'
    );
    $stmt->execute([
        $archived ? date('Y-m-d H:i:s') : null,
        $sightingId,
        $user['id'],
    ]);

    jsonResponse(['success' => true, 'archived' => $archived]);
}
