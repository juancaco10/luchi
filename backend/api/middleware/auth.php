<?php
/**
 * JWT Authentication Middleware
 * Minimal HS256 JWT implementation (no external libraries needed)
 */

require_once __DIR__ . '/../config/database.php';

// ── JWT Helpers ───────────────────────────────────────────────────

function base64UrlEncode(string $data): string
{
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function base64UrlDecode(string $data): string
{
    return base64_decode(strtr($data, '-_', '+/') . str_repeat('=', (4 - strlen($data) % 4) % 4));
}

function generateToken(int $userId, string $email): string
{
    $header  = base64UrlEncode(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
    $payload = base64UrlEncode(json_encode([
        'sub' => $userId,
        'email' => $email,
        'iat' => time(),
        'exp' => time() + (60 * 60 * 24 * 30), // 30 days
    ]));
    $signature = base64UrlEncode(hash_hmac('sha256', "$header.$payload", JWT_SECRET, true));
    return "$header.$payload.$signature";
}

function verifyToken(string $token): ?array
{
    $parts = explode('.', $token);
    if (count($parts) !== 3) return null;

    [$header, $payload, $signature] = $parts;
    $expectedSig = base64UrlEncode(hash_hmac('sha256', "$header.$payload", JWT_SECRET, true));

    if (!hash_equals($expectedSig, $signature)) return null;

    $claims = json_decode(base64UrlDecode($payload), true);
    if (!$claims || !isset($claims['exp']) || $claims['exp'] < time()) return null;

    return $claims;
}

/**
 * Read the Authorization header.
 *
 * On Apache + CGI/FastCGI (which is what Hostinger shared hosting runs)
 * the Authorization header is stripped from $_SERVER unless .htaccess
 * re-injects it. Without these fallbacks every authenticated endpoint
 * returns 401 on a correctly configured-looking deploy.
 */
function getAuthorizationHeader(): string
{
    foreach (['HTTP_AUTHORIZATION', 'REDIRECT_HTTP_AUTHORIZATION'] as $key) {
        if (!empty($_SERVER[$key])) {
            return $_SERVER[$key];
        }
    }

    if (function_exists('apache_request_headers')) {
        foreach (apache_request_headers() as $name => $value) {
            if (strcasecmp($name, 'Authorization') === 0 && $value !== '') {
                return $value;
            }
        }
    }

    return '';
}

/**
 * Require a valid Bearer token.
 * Returns the user's DB row or exits with 401.
 */
function requireAuth(): array
{
    $authHeader = getAuthorizationHeader();
    if (!str_starts_with($authHeader, 'Bearer ')) {
        http_response_code(401);
        echo json_encode(['error' => 'Token requerido']);
        exit;
    }

    $token  = substr($authHeader, 7);
    $claims = verifyToken($token);

    if (!$claims) {
        http_response_code(401);
        echo json_encode(['error' => 'Token inválido o expirado']);
        exit;
    }

    $db   = getDB();
    $stmt = $db->prepare('SELECT * FROM users WHERE id = ?');
    $stmt->execute([$claims['sub']]);
    $user = $stmt->fetch();

    if (!$user) {
        http_response_code(401);
        echo json_encode(['error' => 'Usuario no encontrado']);
        exit;
    }

    return $user;
}

// ── Response Helpers ──────────────────────────────────────────────

function jsonResponse(mixed $data, int $status = 200): never
{
    http_response_code($status);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function jsonError(string $message, int $status = 400): never
{
    jsonResponse(['error' => $message], $status);
}

function sanitize(string $value): string
{
    return trim(strip_tags($value));
}

// ── Login rate limiting ───────────────────────────────────────────
// Throttles by (email, IP) pair. Backed by the login_attempts table.

const LOGIN_MAX_ATTEMPTS = 5;
const LOGIN_WINDOW_MINUTES = 15;

function clientIp(): string
{
    return substr($_SERVER['REMOTE_ADDR'] ?? '0.0.0.0', 0, 45);
}

function requireNotRateLimited(PDO $db, string $email): void
{
    $stmt = $db->prepare(
        'SELECT COUNT(*) FROM login_attempts
         WHERE email = ? AND ip = ?
           AND attempted_at > DATE_SUB(NOW(), INTERVAL ? MINUTE)'
    );
    $stmt->execute([$email, clientIp(), LOGIN_WINDOW_MINUTES]);

    if ((int) $stmt->fetchColumn() >= LOGIN_MAX_ATTEMPTS) {
        jsonError(
            'Demasiados intentos fallidos. Espera unos minutos e inténtalo de nuevo.',
            429
        );
    }
}

function recordFailedLogin(PDO $db, string $email): void
{
    $stmt = $db->prepare(
        'INSERT INTO login_attempts (email, ip) VALUES (?, ?)'
    );
    $stmt->execute([$email, clientIp()]);

    // Opportunistic cleanup so the table cannot grow without bound.
    $db->exec(
        'DELETE FROM login_attempts
         WHERE attempted_at < DATE_SUB(NOW(), INTERVAL 1 DAY)'
    );
}

function clearLoginAttempts(PDO $db, string $email): void
{
    $stmt = $db->prepare(
        'DELETE FROM login_attempts WHERE email = ? AND ip = ?'
    );
    $stmt->execute([$email, clientIp()]);
}
