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

    if (!$user || !password_verify($password, $user['password_hash'])) {
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
