-- ============================================================
-- Insignias reales (conectadas por fin a un GET /badges) y estrellas de
-- minijuegos como fuente de progreso del servidor.
--
-- Ejecutar UNA vez en phpMyAdmin (u otro cliente MySQL) contra la base de
-- producción. Seguro de re-ejecutar: cada sentencia comprueba primero si
-- ya se aplicó.
--
-- ── Por qué ──────────────────────────────────────────────────────
-- El cliente mostraba 6 insignias hardcodeadas que se desbloqueaban SOLO
-- por puntos, con descripciones que prometían otra cosa ("Completa tu
-- primera misión" se conseguía con 10 puntos, sin hacer ninguna misión).
-- El backend sí tenía la lógica de verdad (condition_type real, tabla
-- user_badges) pero no existía ningún GET /badges — el servidor otorgaba
-- insignias que nadie veía jamás.
--
-- También: ningún minijuego avisaba al servidor de nada. `users.points`
-- solo contaba capítulos y avistamientos, así que un niño con progreso
-- real en los juegos podía ver insignias de puntos bloqueadas que ya
-- debería tener. `game_stars` es la fuente que cierra ese hueco.
-- ============================================================

-- ── users.game_stars ───────────────────────────────────────────────
-- Total absoluto de estrellas de minijuegos, según lo último que reportó
-- el cliente vía PUT /me/game-progress. Es un total, no un contador
-- incremental — reenviar el mismo valor (reintento de red) no debe volver
-- a sumar puntos, y guardar solo el total hace eso trivial de garantizar.

SET @col_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'game_stars'
);
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE users ADD COLUMN game_stars INT UNSIGNED NOT NULL DEFAULT 0 AFTER points',
  'SELECT "game_stars ya existe, se omite" AS resultado'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ── badges.condition_type: añadir 'game_stars' ──────────────────────
-- MySQL no admite "ALTER TYPE ADD VALUE" para ENUM; hay que redefinir la
-- columna completa. Se listan todos los valores existentes + el nuevo,
-- así que es seguro de re-ejecutar (un ALTER a un ENUM idéntico no falla,
-- solo no cambia nada).

ALTER TABLE badges
  MODIFY COLUMN condition_type
    ENUM('points','missions','chapters','sightings','game_stars') NOT NULL;

-- ── Insignia "Primera Luz" (misiones) → ya no es alcanzable ─────────
-- La feature de misiones se eliminó del cliente. Dejar esa fila tal cual
-- significaría una insignia imposible de conseguir para siempre; se
-- redefine en el sitio en vez de borrar+reinsertar, así que si algún
-- usuario ya la tenía ganada (con la vieja condición) la conserva en
-- user_badges — no se le quita nada que ya hubiera obtenido.

UPDATE badges
   SET name = 'Primer Paso',
       emoji = '📖',
       description = 'Completa tu primer capítulo',
       condition_type = 'chapters',
       condition_value = 1
 WHERE condition_type = 'missions' AND condition_value = 1;

-- Por si esta migración corre en una base donde esa fila nunca existió
-- (instalación limpia con schema.sql ya actualizado, ver ese archivo):
INSERT INTO badges (name, emoji, description, condition_type, condition_value)
SELECT 'Primer Paso', '📖', 'Completa tu primer capítulo', 'chapters', 1
 WHERE NOT EXISTS (
   SELECT 1 FROM badges WHERE name = 'Primer Paso' AND condition_type = 'chapters'
 ) AND NOT EXISTS (
   SELECT 1 FROM badges WHERE condition_type = 'missions'
 );

-- "Pequeño Científico" pasaba de 15 puntos a "completa un capítulo
-- entero" sin serlo de verdad (era por puntos). Ahora que hay 4 capítulos
-- reales (ver lib/features/education/data/), se corrige a "complétalos
-- todos" para que no sea un duplicado de "Primer Paso".
UPDATE badges
   SET condition_type = 'chapters', condition_value = 4
 WHERE name = 'Pequeño Científico';

-- ── Insignias de minijuegos ──────────────────────────────────────────
-- Con 5 juegos × 10 niveles × 3 estrellas, el máximo son 150.
INSERT INTO badges (name, emoji, description, condition_type, condition_value)
SELECT * FROM (SELECT
  'Primera Estrella' AS name, '🌟' AS emoji,
  'Gana tu primera estrella en un minijuego' AS description,
  'game_stars' AS condition_type, 1 AS condition_value
UNION ALL SELECT
  'Jugador Constante', '🎮',
  'Reúne 25 estrellas en los minijuegos',
  'game_stars', 25
UNION ALL SELECT
  'Estrella del Bosque', '🏅',
  'Reúne 75 estrellas en los minijuegos',
  'game_stars', 75
UNION ALL SELECT
  'Leyenda Luminosa', '🏆',
  'Consigue las 150 estrellas: todos los juegos, todos los niveles, perfectos',
  'game_stars', 150
) AS nuevas
WHERE NOT EXISTS (
  SELECT 1 FROM badges b WHERE b.name = nuevas.name
);

-- Verificación rápida tras ejecutar:
-- DESCRIBE users;   -- debe listar game_stars
-- SELECT name, condition_type, condition_value FROM badges ORDER BY id;
