<?php
/**
 * Sighting Routes — POST /sighting, GET /sightings, GET /my-sightings
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../lib/gamification.php';

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

    $db = getDB();

    $stmt = $db->prepare(
        'INSERT INTO sightings (user_id, lat, lng, quantity, notes, photo_url, location_name)
         VALUES (?, ?, ?, ?, ?, ?, ?)'
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

    // Award points
    $pts = 20; // AppConstants.pointsSighting
    $db->prepare('UPDATE users SET points = points + ? WHERE id = ?')
       ->execute([$pts, $user['id']]);

    // Re-read points, then sync level and badges (lib/gamification.php).
    $totalPoints = syncUserProgress($db, (int) $user['id']);

    jsonResponse([
        'success'       => true,
        'sighting_id'   => $sightingId,
        'points_earned' => $pts,
        'total_points'  => $totalPoints,
        'level'         => getLevelForPoints($totalPoints),
        'level_name'    => getLevelName($totalPoints),
    ], 201);
}

// ── GET /sightings (all public sightings for map) ─────────────────
// Disabled for v1: map is personal only. Exposing coordinates and
// names of minors without a community system is a privacy risk.

if ($method === 'GET' && $path === '/sightings') {
    jsonError('El mapa comunitario está deshabilitado en esta versión', 410);
}

// ── GET /my-sightings ─────────────────────────────────────────────

if ($method === 'GET' && $path === '/my-sightings') {
    $user = requireAuth();
    $db   = getDB();

    $stmt = $db->prepare(
        'SELECT * FROM sightings WHERE user_id = ? ORDER BY created_at DESC LIMIT 100'
    );
    $stmt->execute([$user['id']]);
    $sightings = $stmt->fetchAll();

    jsonResponse([
        'sightings' => array_map(fn($s) => [
            'id'            => (int) $s['id'],
            'lat'           => (float) $s['lat'],
            'lng'           => (float) $s['lng'],
            'quantity'      => (int) $s['quantity'],
            'notes'         => $s['notes'],
            'photo_url'     => $s['photo_url'],
            'location_name' => $s['location_name'],
            'created_at'    => $s['created_at'],
            'is_pending'    => false,
        ], $sightings),
    ]);
}
