<?php
/**
 * Sighting Routes — POST /sightings, GET /sightings, GET /my-sightings,
 * PUT /sightings/{id}, POST /sightings/{id}/archive
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
// ?archived=1 pide los archivados; por defecto solo los activos.

if ($method === 'GET' && $path === '/my-sightings') {
    $user           = requireAuth();
    $db             = getDB();
    $wantArchived   = ($_GET['archived'] ?? '') === '1';

    $stmt = $db->prepare(
        'SELECT * FROM sightings
         WHERE user_id = ? AND archived_at IS ' . ($wantArchived ? 'NOT NULL' : 'NULL') . '
         ORDER BY created_at DESC LIMIT 100'
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
            'updated_at'    => $s['updated_at'],
            'archived_at'   => $s['archived_at'],
            'is_pending'    => false,
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

    $db = getDB();

    // Comprobación de propiedad aparte del UPDATE: `rowCount()` de un
    // UPDATE solo cuenta filas que cambiaron de verdad (PDO/MySQL sin
    // MYSQL_ATTR_FOUND_ROWS), así que guardar sin modificar ningún campo
    // daría 0 filas afectadas y un 404 falso aunque el avistamiento sí
    // exista y sea del usuario.
    $owns = $db->prepare('SELECT 1 FROM sightings WHERE id = ? AND user_id = ?');
    $owns->execute([$sightingId, $user['id']]);
    if (!$owns->fetchColumn()) {
        // O no existe, o no es del usuario autenticado — mismo mensaje en
        // ambos casos para no filtrar si el id pertenece a otra cuenta.
        jsonError('Avistamiento no encontrado', 404);
    }

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

    jsonResponse(['success' => true]);
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
