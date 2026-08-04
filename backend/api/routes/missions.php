<?php
/**
 * Mission Routes — GET /missions, POST /complete-mission
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../lib/gamification.php';

// ── GET /missions ─────────────────────────────────────────────────

if ($method === 'GET' && $path === '/missions') {
    $user = requireAuth();
    $db   = getDB();

    $stmt = $db->prepare(
        'SELECT * FROM missions WHERE is_active = 1 ORDER BY type ASC, id ASC'
    );
    $stmt->execute();
    $missions = $stmt->fetchAll();

    // Get completed mission IDs for this user
    $doneStmt = $db->prepare(
        'SELECT mission_id FROM user_missions WHERE user_id = ?'
    );
    $doneStmt->execute([$user['id']]);
    $completedIds = array_column($doneStmt->fetchAll(), 'mission_id');

    $result = array_map(fn($m) => [
        'id'            => (int) $m['id'],
        'title'         => $m['title'],
        'description'   => $m['description'],
        'type'          => $m['type'],
        'points_reward' => (int) $m['points_reward'],
        'icon'          => $m['icon'],
        'how_to'        => $m['how_to'],
        'tip'           => $m['tip'],
        'is_completed'  => in_array($m['id'], $completedIds),
    ], $missions);

    jsonResponse(['missions' => $result]);
}

// ── POST /complete-mission ────────────────────────────────────────

if ($method === 'POST' && $path === '/complete-mission') {
    $user = requireAuth();
    $body = json_decode(file_get_contents('php://input'), true) ?? [];

    $missionId = (int) ($body['mission_id'] ?? 0);
    if ($missionId <= 0) jsonError('mission_id inválido');

    $db = getDB();

    // Verify mission exists
    $stmt = $db->prepare('SELECT * FROM missions WHERE id = ? AND is_active = 1');
    $stmt->execute([$missionId]);
    $mission = $stmt->fetch();
    if (!$mission) jsonError('Misión no encontrada', 404);

    // Idempotent: skip if already completed
    $stmt = $db->prepare(
        'INSERT IGNORE INTO user_missions (user_id, mission_id) VALUES (?, ?)'
    );
    $stmt->execute([$user['id'], $missionId]);
    $wasNew = $stmt->rowCount() > 0;

    $pointsEarned = 0;
    $totalPoints  = (int) $user['points'];
    if ($wasNew) {
        $pointsEarned = (int) $mission['points_reward'];

        // Add points to user
        $db->prepare('UPDATE users SET points = points + ? WHERE id = ?')
           ->execute([$pointsEarned, $user['id']]);

        // Re-read points, then sync level and badges (lib/gamification.php).
        // This also awards the 'missions' badges, which the previous
        // implementation could never grant.
        $totalPoints = syncUserProgress($db, (int) $user['id']);
    }

    jsonResponse([
        'success'       => true,
        'already_done'  => !$wasNew,
        'points_earned' => $pointsEarned,
        'total_points'  => $totalPoints,
        'level'         => getLevelForPoints($totalPoints),
        'level_name'    => getLevelName($totalPoints),
    ]);
}
