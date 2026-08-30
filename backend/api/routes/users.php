<?php
/**
 * User Routes — POST /register, POST /login, GET /me
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../lib/gamification.php';

// ── Helper: format user for response ─────────────────────────────
// getLevelName() and updateUserLevel() now live in lib/gamification.php
// (they were duplicated here and in chapters.php, a fatal redeclare).

function formatUser(array $user): array
{
    return [
        'id'         => (int) $user['id'],
        'name'       => $user['name'],
        'email'      => $user['email'],
        'points'     => (int) $user['points'],
        'level'      => (int) $user['level'],
        'levelName'  => getLevelName((int) $user['points']),
        'avatar_url' => $user['avatar_url'],
        'nickname'   => $user['nickname'],
        'country'    => $user['country'],
        'city'       => $user['city'],
        'created_at' => $user['created_at'],
    ];
}

/** Stores a technical declaration; legal verification remains a separate concern. */
function requiredConsent(array $body): array
{
    $consent = $body['parental_consent'] ?? null;
    if (!is_array($consent) || ($consent['accepted'] ?? false) !== true) {
        jsonError('Se requiere consentimiento parental antes de crear una cuenta', 403);
    }

    $timestamp = $consent['timestamp'] ?? '';
    $policy = trim((string) ($consent['policy_version'] ?? ''));
    if (!is_string($timestamp) || strtotime($timestamp) === false || $policy === '' || strlen($policy) > 64) {
        jsonError('Datos de consentimiento inválidos');
    }
    return [gmdate('Y-m-d H:i:s', strtotime($timestamp)), $policy];
}

// ── POST /register ────────────────────────────────────────────────

if ($method === 'POST' && $path === '/register') {
    $body = json_decode(file_get_contents('php://input'), true) ?? [];

    $name     = sanitize($body['name']     ?? '');
    $email    = strtolower(trim($body['email']    ?? ''));
    $password = $body['password'] ?? '';
    [$consentAt, $consentPolicy] = requiredConsent($body);

    // Validation
    if (empty($name) || strlen($name) < 2) {
        jsonError('El nombre debe tener al menos 2 caracteres');
    }
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        jsonError('Correo electrónico inválido');
    }
    if (strlen($password) < 6) {
        jsonError('La contraseña debe tener al menos 6 caracteres');
    }

    $db = getDB();
    requireIpNotRateLimited($db, 'register', 10, 60);

    // Check duplicate
    $check = $db->prepare('SELECT id FROM users WHERE email = ?');
    $check->execute([$email]);
    if ($check->fetch()) {
        jsonError('Ya existe una cuenta con ese correo', 409);
    }

    recordIpAttempt($db, 'register');

    // Insert
    $hash = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
    $stmt = $db->prepare(
        'INSERT INTO users (name, email, password_hash, parental_consent_status,
          parental_consent_at, parental_consent_policy_version, parental_consent_method)
         VALUES (?, ?, ?, 1, ?, ?, "in_app_declaration")'
    );
    $stmt->execute([$name, $email, $hash, $consentAt, $consentPolicy]);
    $userId = (int) $db->lastInsertId();

    $user = $db->prepare('SELECT * FROM users WHERE id = ?');
    $user->execute([$userId]);
    $userRow = $user->fetch();

    $token = generateToken($userId, $email);
    jsonResponse([
        'token' => $token,
        'user'  => formatUser($userRow),
    ], 201);
}

// ── POST /login ───────────────────────────────────────────────────

if ($method === 'POST' && $path === '/login') {
    $body = json_decode(file_get_contents('php://input'), true) ?? [];

    $email    = strtolower(trim($body['email']    ?? ''));
    $password = $body['password'] ?? '';

    if (empty($email) || empty($password)) {
        jsonError('Correo y contraseña son requeridos');
    }

    $db = getDB();

    // Brute-force protection: these are children's accounts, and without
    // this an attacker can try passwords at line speed.
    requireNotRateLimited($db, $email);

    $stmt = $db->prepare('SELECT * FROM users WHERE email = ?');
    $stmt->execute([$email]);
    $user = $stmt->fetch();

    // password_hash es NULL en cuentas creadas por Google: pasarlo tal
    // cual a password_verify() emite un E_DEPRECATED que el
    // set_error_handler de index.php convierte en 500. Se descarta antes.
    if (!$user || $user['password_hash'] === null
        || !password_verify($password, $user['password_hash'])) {
        recordFailedLogin($db, $email);
        jsonError('Credenciales incorrectas', 401);
    }

    clearLoginAttempts($db, $email);

    $token = generateToken((int) $user['id'], $email);
    jsonResponse([
        'token' => $token,
        'user'  => formatUser($user),
    ]);
}

// ── POST /auth/google ─────────────────────────────────────────────
// Verifica un idToken de Google Sign-In y devuelve el mismo contrato que
// /login: {token, user}. El cliente nunca ve la diferencia entre este
// endpoint y el login normal.

/**
 * Verifica un idToken de Google contra el endpoint tokeninfo de Google
 * (delegamos la verificación de firma RS256 en Google en vez de
 * implementarla a mano) y comprueba `aud` contra nuestro propio
 * GOOGLE_CLIENT_ID.
 *
 * Esa comprobación de `aud` es la que importa de verdad: sin ella, un
 * idToken válido emitido para CUALQUIER OTRA app de Google (firma
 * correcta, sin caducar, todo en regla) sería aceptado igual, porque
 * "válido" y "válido para nosotros" no son lo mismo. tokeninfo por sí
 * solo solo certifica lo primero.
 *
 * Devuelve los claims si todo encaja, o null si el token no sirve.
 */
function googleVerifyIdToken(string $idToken): ?array
{
    $url = 'https://oauth2.googleapis.com/tokeninfo?id_token=' . urlencode($idToken);

    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 8);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 5);
    $body = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlErrno = curl_errno($ch);
    curl_close($ch);

    // Fallo de red hacia Google: no es lo mismo que "token inválido", pero
    // el efecto para el cliente es el mismo (no podemos confiar en él).
    if ($curlErrno !== 0 || $httpCode !== 200 || $body === false) {
        return null;
    }

    $claims = json_decode($body, true);
    if (!is_array($claims)) return null;

    // 1. Destinado a NUESTRA app, no a otra cualquiera.
    if (($claims['aud'] ?? null) !== GOOGLE_CLIENT_ID) return null;

    // 2. Issuer es Google (tokeninfo puede en teoría recibir cualquier JWT
    // bien formado de otro origen si algún día cambia su comportamiento;
    // ser explícitos aquí no cuesta nada).
    $iss = $claims['iss'] ?? '';
    if ($iss !== 'https://accounts.google.com' && $iss !== 'accounts.google.com') {
        return null;
    }

    // 3. Correo verificado por Google: es lo que hace seguro vincular por
    // email más abajo, en vez de crear siempre una cuenta nueva.
    // tokeninfo devuelve los booleanos como string ("true"/"false"), no
    // como bool JSON — se aceptan ambas formas por si eso cambia.
    $emailVerified = $claims['email_verified'] ?? false;
    if ($emailVerified !== true && $emailVerified !== 'true') return null;

    // 4. exp ya lo valida tokeninfo (devuelve error si caducó), pero se
    // revalida aquí para no depender únicamente de su comportamiento.
    if (!isset($claims['exp']) || (int) $claims['exp'] < time()) return null;

    if (empty($claims['sub']) || empty($claims['email'])) return null;

    return $claims;
}

if ($method === 'POST' && $path === '/auth/google') {
    $body = json_decode(file_get_contents('php://input'), true) ?? [];
    $idToken = $body['id_token'] ?? '';

    if (empty($idToken)) {
        jsonError('id_token es requerido');
    }

    $claims = googleVerifyIdToken($idToken);
    if ($claims === null) {
        jsonError('Token de Google inválido', 401);
    }

    $googleSub = $claims['sub'];
    $email     = strtolower(trim($claims['email']));
    $name      = sanitize($claims['name'] ?? explode('@', $email)[0]);
    $avatarUrl = $claims['picture'] ?? null;

    $db = getDB();

    // 1. ¿Ya hay una cuenta vinculada a esta cuenta de Google?
    $stmt = $db->prepare('SELECT * FROM users WHERE google_sub = ?');
    $stmt->execute([$googleSub]);
    $user = $stmt->fetch();

    if (!$user) {
        // 2. ¿Existe una cuenta con este correo (creada con contraseña)?
        // email_verified ya se comprobó arriba, así que vincular es
        // seguro: es la misma persona demostrando ser dueña del correo.
        $stmt = $db->prepare('SELECT * FROM users WHERE email = ?');
        $stmt->execute([$email]);
        $existing = $stmt->fetch();

        if ($existing) {
            $update = $db->prepare(
                'UPDATE users SET google_sub = ? WHERE id = ?'
            );
            $update->execute([$googleSub, $existing['id']]);

            $stmt = $db->prepare('SELECT * FROM users WHERE id = ?');
            $stmt->execute([$existing['id']]);
            $user = $stmt->fetch();
        } else {
            [$consentAt, $consentPolicy] = requiredConsent($body);
            // 3. Cuenta nueva. Sin contraseña: password_hash queda NULL.
            $insert = $db->prepare(
                'INSERT INTO users (name, email, google_sub, auth_provider, avatar_url,
                  parental_consent_status, parental_consent_at,
                  parental_consent_policy_version, parental_consent_method)
                 VALUES (?, ?, ?, \'google\', ?, 1, ?, ?, "in_app_declaration")'
            );
            $insert->execute([$name, $email, $googleSub, $avatarUrl, $consentAt, $consentPolicy]);
            $userId = (int) $db->lastInsertId();

            $stmt = $db->prepare('SELECT * FROM users WHERE id = ?');
            $stmt->execute([$userId]);
            $user = $stmt->fetch();
        }
    }

    $token = generateToken((int) $user['id'], $user['email']);
    jsonResponse([
        'token' => $token,
        'user'  => formatUser($user),
    ]);
}

// ── POST /auth/guest ──────────────────────────────────────────────
// Crea un usuario invitado y devuelve una sesión.

if ($method === 'POST' && $path === '/auth/guest') {
    $body = json_decode(file_get_contents('php://input'), true) ?? [];
    [$consentAt, $consentPolicy] = requiredConsent($body);
    $db = getDB();
    // Sin este límite, POST /auth/guest crea una cuenta nueva por
    // llamada sin fricción alguna — creación masiva de usuarios trivial.
    requireIpNotRateLimited($db, 'guest', 10, 60);
    recordIpAttempt($db, 'guest');
    $guestId = rand(10000, 99999);
    $name = "Invitado $guestId";
    $email = "invitado_$guestId@luciernagas.local";

    $insert = $db->prepare(
        'INSERT INTO users (name, email, auth_provider, parental_consent_status,
          parental_consent_at, parental_consent_policy_version, parental_consent_method)
         VALUES (?, ?, \'guest\', 1, ?, ?, "in_app_declaration")'
    );
    $insert->execute([$name, $email, $consentAt, $consentPolicy]);
    $userId = (int) $db->lastInsertId();

    $stmt = $db->prepare('SELECT * FROM users WHERE id = ?');
    $stmt->execute([$userId]);
    $user = $stmt->fetch();

    $token = generateToken((int) $user['id'], $user['email']);
    jsonResponse([
        'token' => $token,
        'user'  => formatUser($user),
    ]);
}

// ── GET /me ───────────────────────────────────────────────────────

if ($method === 'GET' && $path === '/me') {
    $user = requireAuth();
    jsonResponse(['user' => formatUser($user)]);
}

// ── PUT /me — actualización parcial del perfil ──────────────────────
// País/ciudad se piden una sola vez, la primera vez que el usuario va a
// publicar un avistamiento (ver
// lib/features/sightings/screens/location_setup_screen.dart en el
// cliente); avatar_url se cambia desde el selector del perfil
// (lib/features/profile/widgets/avatar_picker_sheet.dart). Cada campo se
// actualiza solo si viene en el body — antes exigía country+city siempre,
// así que guardar solo un avatar nuevo fallaba con 400 por falta de
// ubicación.

if ($method === 'PUT' && $path === '/me') {
    $user = requireAuth();
    $body = json_decode(file_get_contents('php://input'), true) ?? [];

    $sets   = [];
    $params = [];

    if (array_key_exists('country', $body) || array_key_exists('city', $body)) {
        $country = sanitize($body['country'] ?? '');
        $city    = sanitize($body['city']    ?? '');
        if ($country === '' || $city === '') {
            jsonError('País y ciudad son requeridos');
        }
        $sets[]   = 'country = ?';
        $params[] = $country;
        $sets[]   = 'city = ?';
        $params[] = $city;
    }

    if (array_key_exists('nickname', $body)) {
        $nickname = trim((string) $body['nickname']);
        // Apodo corto para el feed: 1-12 caracteres, sin espacios (debe
        // caber en una sola línea de las tarjetas de avistamientos). Se
        // respeta el estilo del usuario tal cual lo escribe — no se
        // capitaliza — y se guarda el mismo valor que luego se muestra.
        if ($nickname === '' || mb_strlen($nickname) > 12 || preg_match('/\s/', $nickname)) {
            jsonError('El apodo debe tener entre 1 y 12 caracteres, sin espacios');
        }
        $sets[]   = 'nickname = ?';
        $params[] = $nickname;
    }

    if (array_key_exists('avatar_url', $body)) {
        $avatar = (string) $body['avatar_url'];
        // Lista blanca server-side, no solo del lado del cliente: el
        // selector del perfil (avatar_picker_sheet.dart) solo ofrece estos
        // 18 (ver assets/images/avatars/), y este es el único de los tres
        // puntos que decide qué es válido de verdad. `avatar_url` es un
        // VARCHAR(500) libre — sin este check, una petición manipulada
        // podría guardar cualquier URL externa y mostrarla dentro de una
        // app para menores.
        //
        // El avatar de Google (una URL https://…) NO pasa por aquí: se
        // escribe una sola vez, directo desde el idToken ya verificado, en
        // la ruta /auth/google (`$claims['picture']` más abajo en este
        // archivo) — nunca a través de este PUT. Por eso aquí se rechaza
        // cualquier cosa que no sea uno de los 18 nombres fijos, sin
        // excepción para https.
        if (!preg_match('/^avatar(0[1-9]|1[0-8])\.png$/', $avatar)) {
            jsonError('Avatar no válido');
        }
        $sets[]   = 'avatar_url = ?';
        $params[] = $avatar;
    }

    if (empty($sets)) {
        jsonError('Nada que actualizar');
    }

    $params[] = $user['id'];

    $db = getDB();
    $db->prepare('UPDATE users SET ' . implode(', ', $sets) . ' WHERE id = ?')
       ->execute($params);

    // Releer la fila para devolver el estado real ya guardado, en vez de
    // asumir que el UPDATE hizo exactamente lo que se pidió.
    $stmt = $db->prepare('SELECT * FROM users WHERE id = ?');
    $stmt->execute([$user['id']]);
    $updated = $stmt->fetch();

    jsonResponse(['user' => formatUser($updated)]);
}

// ── PUT /me/game-progress — sincronizar estrellas de minijuegos ────
//
// El progreso de los 5 minijuegos vive local-autoritativo en el
// dispositivo (Hive, `games_box` — ver
// lib/features/games/providers/games_progress_provider.dart): el
// servidor no decide si un nivel se ganó, solo se entera de cuántas
// estrellas hay en total para poder otorgar puntos e insignias
// consistentes entre dispositivos.
//
// body: {"stars": N} — el TOTAL absoluto de estrellas del jugador, no un
// incremento. Eso es lo que hace este endpoint idempotente: reenviar la
// misma llamada (reintento de red, doble tap) nunca vuelve a sumar,
// porque solo se pagan puntos por `stars - game_stars_actual` y ese
// delta es 0 la segunda vez. Es la misma idea que ya usa la cola offline
// de avistamientos, aplicada a un contador en vez de a una lista.
if ($method === 'PUT' && $path === '/me/game-progress') {
    $user  = requireAuth();
    $body  = json_decode(file_get_contents('php://input'), true) ?? [];
    $stars = filter_var($body['stars'] ?? null, FILTER_VALIDATE_INT);

    // 5 minijuegos × 10 niveles (AppConstants.levelsPerGame) × 3 estrellas
    // por nivel. Un total por encima de esto no es alcanzable jugando y
    // solo puede venir de un cliente manipulado (Hive editado a mano,
    // APK parcheado) — se rechaza en vez de aceptarlo silenciosamente.
    $maxGameStars = 5 * 10 * 3;

    if ($stars === false || $stars === null || $stars < 0 || $stars > $maxGameStars) {
        jsonError('stars debe ser un entero entre 0 y ' . $maxGameStars);
    }

    $db = getDB();

    // Transacción con `FOR UPDATE`: sin el lock de fila, dos llamadas
    // concurrentes (doble tap, reintento de red superpuesto) podrían leer
    // el mismo `previousStars` antes de que ninguna escriba, y la que
    // termine después pisaría el delta de la otra (lost update).
    $db->beginTransaction();
    try {
        $stmt = $db->prepare('SELECT game_stars FROM users WHERE id = ? FOR UPDATE');
        $stmt->execute([$user['id']]);
        $previousStars = (int) $stmt->fetchColumn();

        // Nunca dejar que el total baje: el cliente siempre envía su máximo
        // conocido, así que un valor menor solo puede venir de un dispositivo
        // desactualizado o un reintento fuera de orden — no de progreso
        // perdido de verdad.
        $newStars = max($previousStars, $stars);
        $delta    = $newStars - $previousStars;

        // Mismo valor por estrella que AppConstants.pointsGameStar en el
        // cliente (lib/core/utils/constants.dart) — deben mantenerse en sync.
        $pointsGained = $delta * 5;

        $db->prepare('UPDATE users SET game_stars = ?, points = points + ? WHERE id = ?')
           ->execute([$newStars, $pointsGained, $user['id']]);

        $totalPoints = syncUserProgress($db, (int) $user['id']);

        $db->commit();
    } catch (Throwable $e) {
        $db->rollBack();
        jsonError('No se pudo guardar el progreso', 500);
    }

    jsonResponse([
        'success'       => true,
        'game_stars'    => $newStars,
        'points_earned' => $pointsGained,
        'total_points'  => $totalPoints,
        'level'         => getLevelForPoints($totalPoints),
        'level_name'    => getLevelName($totalPoints),
    ]);
}

// ── DELETE /me ────────────────────────────────────────────────────
// Account deletion is mandatory for Google Play (and for our own
// privacy policy). Every child-owned row hangs off users.id with
// ON DELETE CASCADE, so removing this row removes their sightings,
// chapter/mission progress and badges too.
//
// Lo que el CASCADE de la base de datos NO hace por sí solo:
//   1. Los archivos de foto en backend/api/uploads/sightings/ (ver
//      uploads.php) son ficheros en disco, no filas — hay que borrarlos a
//      mano antes de que la fila que los referencia desaparezca, o
//      quedarían huérfanos para siempre.
//   2. login_attempts no tiene FK a users (guarda el email, no el id, para
//      poder rate-limitar intentos fallidos incluso antes del primer
//      login exitoso) — se limpia aparte para no dejar un rastro del
//      correo tras borrar la cuenta.

if ($method === 'DELETE' && $path === '/me') {
    $user = requireAuth();
    $db   = getDB();

    $photos = $db->prepare('SELECT photo_url FROM sightings WHERE user_id = ? AND photo_url IS NOT NULL');
    $photos->execute([(int) $user['id']]);
    $uploadsDir = realpath(__DIR__ . '/../uploads/sightings');

    foreach ($photos->fetchAll(PDO::FETCH_COLUMN) as $photoUrl) {
        $filename = basename(parse_url($photoUrl, PHP_URL_PATH) ?? '');
        if ($filename === '') continue;

        // basename() ya descarta cualquier "../", pero se resuelve la ruta
        // real y se confirma que sigue dentro de uploads/sightings antes de
        // borrar — no fiarse de una cadena construida a partir de un campo
        // que en teoría podría no venir de nuestro propio uploads.php.
        $fullPath = $uploadsDir . '/' . $filename;
        $real     = realpath($fullPath);
        if ($real !== false && $uploadsDir !== false && str_starts_with($real, $uploadsDir)) {
            @unlink($real);
        }
    }

    $db->prepare('DELETE FROM login_attempts WHERE email = ?')
       ->execute([$user['email']]);

    $stmt = $db->prepare('DELETE FROM users WHERE id = ?');
    $stmt->execute([(int) $user['id']]);

    jsonResponse(['success' => true, 'deleted' => true]);
}
