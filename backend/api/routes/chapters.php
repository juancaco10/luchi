<?php
/**
 * Chapter Routes — GET /chapters, POST /complete-chapter
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../lib/gamification.php';

// ── GET /chapters ─────────────────────────────────────────────────

if ($method === 'GET' && $path === '/chapters') {
    $user = requireAuth();
    $db   = getDB();

    // Get all active chapters
    $stmt = $db->prepare(
        'SELECT * FROM chapters WHERE is_active = 1 ORDER BY order_index ASC'
    );
    $stmt->execute();
    $chapters = $stmt->fetchAll();

    // Get completed chapter IDs for this user
    $doneStmt = $db->prepare(
        'SELECT chapter_id FROM user_chapters WHERE user_id = ?'
    );
    $doneStmt->execute([$user['id']]);
    $completedIds = array_column($doneStmt->fetchAll(), 'chapter_id');

    // Build response with unlock logic
    $result = [];
    foreach ($chapters as $i => $ch) {
        $isCompleted = in_array($ch['id'], $completedIds);
        // First chapter always unlocked; others unlock when previous is done
        $isUnlocked = $i === 0 || in_array($chapters[$i - 1]['id'], $completedIds);

        $result[] = [
            'id'            => (int) $ch['id'],
            'title'         => $ch['title'],
            'description'   => $ch['description'],
            'video_url'     => $ch['video_url'],
            'thumbnail_url' => $ch['thumbnail_url'],
            'order_index'   => (int) $ch['order_index'],
            'points_reward' => (int) $ch['points_reward'],
            'facts'         => json_decode($ch['facts'] ?? '[]', true),
            'quiz'          => json_decode($ch['quiz']  ?? '[]', true),
            'is_completed'  => $isCompleted,
            'is_unlocked'   => $isUnlocked,
        ];
    }

    jsonResponse(['chapters' => $result]);
}

// ── POST /complete-chapter ────────────────────────────────────────

if ($method === 'POST' && $path === '/complete-chapter') {
    $user = requireAuth();
    $body = json_decode(file_get_contents('php://input'), true) ?? [];

    $chapterId = (int) ($body['chapter_id'] ?? 0);
    if ($chapterId <= 0) jsonError('chapter_id inválido');

    $db = getDB();

    // Check chapter exists
    $stmt = $db->prepare('SELECT id, points_reward FROM chapters WHERE id = ? AND is_active = 1');
    $stmt->execute([$chapterId]);
    $chapter = $stmt->fetch();
    if (!$chapter) jsonError('Capítulo no encontrado', 404);

    // Idempotent insert
    $stmt = $db->prepare(
        'INSERT IGNORE INTO user_chapters (user_id, chapter_id) VALUES (?, ?)'
    );
    $stmt->execute([$user['id'], $chapterId]);
    $wasNew = $stmt->rowCount() > 0;

    $pointsEarned = 0;
    $totalPoints  = (int) $user['points'];
    if ($wasNew) {
        $pointsEarned = (int) $chapter['points_reward'];
        $stmt = $db->prepare(
            'UPDATE users SET points = points + ? WHERE id = ?'
        );
        $stmt->execute([$pointsEarned, $user['id']]);

        // Re-read points, then sync level and badges (lib/gamification.php)
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
