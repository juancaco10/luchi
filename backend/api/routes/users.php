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
        'created_at' => $user['created_at'],
    ];
}

// ── POST /register ────────────────────────────────────────────────

if ($method === 'POST' && $path === '/register') {
    $body = json_decode(file_get_contents('php://input'), true) ?? [];

    $name     = sanitize($body['name']     ?? '');
    $email    = strtolower(trim($body['email']    ?? ''));
    $password = $body['password'] ?? '';

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

    // Check duplicate
    $check = $db->prepare('SELECT id FROM users WHERE email = ?');
    $check->execute([$email]);
    if ($check->fetch()) {
        jsonError('Ya existe una cuenta con ese correo', 409);
    }

    // Insert
    $hash = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
    $stmt = $db->prepare(
        'INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)'
    );
    $stmt->execute([$name, $email, $hash]);
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
            // 3. Cuenta nueva. Sin contraseña: password_hash queda NULL.
            $insert = $db->prepare(
                'INSERT INTO users (name, email, google_sub, auth_provider, avatar_url)
                 VALUES (?, ?, ?, \'google\', ?)'
            );
            $insert->execute([$name, $email, $googleSub, $avatarUrl]);
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

// ── GET /me ───────────────────────────────────────────────────────

if ($method === 'GET' && $path === '/me') {
    $user = requireAuth();
    jsonResponse(['user' => formatUser($user)]);
}

// ── DELETE /me ────────────────────────────────────────────────────
// Account deletion is mandatory for Google Play (and for our own
// privacy policy). Every child-owned row hangs off users.id with
// ON DELETE CASCADE, so removing this row removes their sightings,
// chapter/mission progress and badges too.

if ($method === 'DELETE' && $path === '/me') {
    $user = requireAuth();

    $db   = getDB();
    $stmt = $db->prepare('DELETE FROM users WHERE id = ?');
    $stmt->execute([(int) $user['id']]);

    jsonResponse(['success' => true, 'deleted' => true]);
}
