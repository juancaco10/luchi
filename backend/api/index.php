<?php
/**
 * Router — Guardianes de las Luciérnagas API
 * Hostinger-compatible single entry point
 */

// ── Never leak a PHP error/stack trace into what the client expects to be
// JSON. Every route that fails on purpose already calls jsonError(), which
// returns {"error": "..."}. This is the fallback for the failures nobody
// wrote a jsonError() for — a DB hiccup, an unexpected null, etc. Without
// it, a fatal error prints HTML (or nothing) instead of JSON, and the
// Flutter client's error interceptor — which reads response.data['error'] —
// has nothing to read.
ini_set('display_errors', '0');
error_reporting(E_ALL);

set_exception_handler(function (Throwable $e): void {
    error_log('[luchi-api] uncaught: ' . $e);
    if (!headers_sent()) {
        header('Content-Type: application/json; charset=UTF-8');
        http_response_code(500);
    }
    echo json_encode(['error' => 'Error inesperado del servidor.']);
    exit;
});

set_error_handler(function (int $severity, string $message, string $file, int $line): bool {
    throw new ErrorException($message, 0, $severity, $file, $line);
});

require_once __DIR__ . '/config/database.php';

// ── CORS Headers ──────────────────────────────────────────────────
// The Android app does not need CORS at all; only the Flutter web build
// does, and only from our own origin. ALLOWED_ORIGINS is defined in
// config/database.php — never widen this back to '*' on an authenticated API.
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if ($origin !== '' && in_array($origin, ALLOWED_ORIGINS, true)) {
    header('Access-Control-Allow-Origin: ' . $origin);
    header('Vary: Origin');
}
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json; charset=UTF-8');

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// ── Parse route ───────────────────────────────────────────────────
// Strip the script's directory prefix (e.g. '/api' when deployed at
// public_html/api/index.php). Must be a prefix removal, not str_replace,
// which would delete every occurrence anywhere in the URI.
$requestUri = $_SERVER['REQUEST_URI'] ?? '/';
$scriptName = rtrim(str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? '')), '/');

$path = $requestUri;
if ($scriptName !== '' && str_starts_with($path, $scriptName)) {
    $path = substr($path, strlen($scriptName));
}
$path   = parse_url($path, PHP_URL_PATH) ?? '/';
$path   = '/' . trim($path, '/');
$method = $_SERVER['REQUEST_METHOD'];

// ── Test Endpoint (Safe) ──────────────────────────────────────────
// ── Shared helpers ────────────────────────────────────────────────
require_once __DIR__ . '/lib/gamification.php';

// ── Routes ────────────────────────────────────────────────────────
require_once __DIR__ . '/routes/users.php';
require_once __DIR__ . '/routes/chapters.php';
require_once __DIR__ . '/routes/sightings.php';
require_once __DIR__ . '/routes/badges.php';
require_once __DIR__ . '/routes/uploads.php';

// 404 fallback
http_response_code(404);
echo json_encode(['error' => 'Ruta no encontrada', 'path' => $path]);
