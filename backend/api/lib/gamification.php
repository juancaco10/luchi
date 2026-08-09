<?php
/**
 * Shared gamification helpers — levels and badges.
 *
 * These used to live duplicated inside routes/users.php and
 * routes/chapters.php (which fataled with "cannot redeclare"), and the
 * badge logic was only reachable from chapters.php by include order.
 * Single definition here, included once from index.php before the routes.
 *
 * Source of truth for thresholds: lib/core/utils/constants.dart in the
 * Flutter client. Keep both in sync.
 */

require_once __DIR__ . '/../config/database.php';

function getLevelName(int $pts): string
{
    if ($pts >= 400) return 'Maestro Guardián';
    if ($pts >= 200) return 'Guardián';
    if ($pts >= 100) return 'Explorador';
    return 'Observador';
}

function getLevelForPoints(int $points): int
{
    if ($points >= 400) return 4;
    if ($points >= 200) return 3;
    if ($points >= 100) return 2;
    return 1;
}

function updateUserLevel(PDO $db, int $userId, int $points): void
{
    $stmt = $db->prepare('UPDATE users SET level = ? WHERE id = ?');
    $stmt->execute([getLevelForPoints($points), $userId]);
}

/**
 * Award every badge whose condition the user now satisfies.
 *
 * Previously only 'points' was handled, so the seeded 'missions',
 * 'chapters' and 'sightings' badges could never be earned.
 */
function awardBadgesIfEarned(PDO $db, int $userId, int $points, int $gameStars = 0): void
{
    // Badges this user has not earned yet
    $stmt = $db->prepare(
        'SELECT b.* FROM badges b
         LEFT JOIN user_badges ub ON ub.badge_id = b.id AND ub.user_id = ?
         WHERE ub.id IS NULL'
    );
    $stmt->execute([$userId]);
    $pending = $stmt->fetchAll();

    if (!$pending) return;

    // Counters are computed lazily — only if some pending badge needs them.
    $counts = [];
    $countFor = function (string $type) use ($db, $userId, &$counts): int {
        if (array_key_exists($type, $counts)) return $counts[$type];

        // 'missions' ya no es un tipo de condición vigente: la feature de
        // misiones se eliminó del cliente y ninguna insignia activa lo usa
        // (ver database/migrations/05_2026_profile_badges.sql). La tabla
        // `user_missions` sigue existiendo — no se borró, por si se
        // reactivara — pero nada vuelve a leerla desde aquí.
        $table = match ($type) {
            'chapters'  => 'user_chapters',
            'sightings' => 'sightings',
            default     => null,
        };
        if ($table === null) return $counts[$type] = 0;

        $stmt = $db->prepare("SELECT COUNT(*) FROM {$table} WHERE user_id = ?");
        $stmt->execute([$userId]);
        return $counts[$type] = (int) $stmt->fetchColumn();
    };

    $insert = $db->prepare(
        'INSERT IGNORE INTO user_badges (user_id, badge_id) VALUES (?, ?)'
    );

    foreach ($pending as $badge) {
        $type     = $badge['condition_type'];
        $required = (int) $badge['condition_value'];

        $actual = match ($type) {
            'points'     => $points,
            'game_stars' => $gameStars,
            default      => $countFor($type),
        };

        if ($actual >= $required) {
            $insert->execute([$userId, (int) $badge['id']]);
        }
    }
}

/**
 * Re-read el puntaje y las estrellas de juego del usuario, y sincroniza
 * nivel + insignias. Llamar después de cualquier cambio en puntos o en
 * `game_stars` para que toda ruta quede consistente.
 */
function syncUserProgress(PDO $db, int $userId): int
{
    $stmt = $db->prepare('SELECT points, game_stars FROM users WHERE id = ?');
    $stmt->execute([$userId]);
    $row    = $stmt->fetch();
    $points = (int) $row['points'];

    updateUserLevel($db, $userId, $points);
    awardBadgesIfEarned($db, $userId, $points, (int) $row['game_stars']);

    return $points;
}
