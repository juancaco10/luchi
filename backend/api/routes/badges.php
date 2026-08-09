<?php
/**
 * Badge Routes — GET /badges
 *
 * Antes no existía: el backend otorgaba insignias de verdad en
 * `user_badges` (ver lib/gamification.php) pero ningún endpoint las
 * devolvía nunca, así que el cliente mostraba 6 insignias inventadas,
 * calculadas solo por puntos, con descripciones que prometían otra cosa.
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/auth.php';

// ── GET /badges ─────────────────────────────────────────────────────
// Devuelve TODAS las insignias, no solo las conseguidas: mostrar lo que
// falta ("Estrella del Bosque — 75 estrellas") es la mitad del incentivo
// de un sistema de logros para niños.

if ($method === 'GET' && $path === '/badges') {
    $user = requireAuth();
    $db   = getDB();

    $stmt = $db->prepare(
        'SELECT b.id, b.name, b.emoji, b.description, b.condition_type,
                b.condition_value, ub.earned_at
           FROM badges b
           LEFT JOIN user_badges ub
             ON ub.badge_id = b.id AND ub.user_id = ?
          ORDER BY b.id'
    );
    $stmt->execute([$user['id']]);
    $rows = $stmt->fetchAll();

    header('Cache-Control: public, max-age=3600');
    jsonResponse([
        'badges' => array_map(fn($b) => [
            'id'              => (int) $b['id'],
            'name'            => $b['name'],
            'emoji'           => $b['emoji'],
            'description'     => $b['description'],
            'condition_type'  => $b['condition_type'],
            'condition_value' => (int) $b['condition_value'],
            'earned'          => $b['earned_at'] !== null,
            'earned_at'       => $b['earned_at'],
        ], $rows),
    ]);
}
