-- ============================================================
-- Avistamientos sociales: corazones (likes), moderación previa y el feed
-- comunitario que hasta ahora devolvía 410.
--
-- Ejecutar UNA vez en phpMyAdmin (u otro cliente MySQL) contra la base de
-- producción. Seguro de re-ejecutar: cada sentencia comprueba primero si
-- ya se aplicó, así que correrla dos veces por error no falla ni duplica.
--
-- ── Por qué moderación ────────────────────────────────────────────
-- `GET /sightings` estaba deshabilitado a propósito: publicar fotos y
-- coordenadas de menores entre menores, sin revisión previa, es justo el
-- riesgo que ese 410 evitaba (ver docs/PRIVACY.md). Al abrir el feed, la
-- moderación deja de ser opcional: todo avistamiento nace en 'pending' y
-- NO aparece para nadie más hasta que un moderador lo aprueba.
--
-- Consecuencia importante al desplegar: los avistamientos que ya existen
-- se quedarían invisibles en el feed, porque la columna nace con DEFAULT
-- 'pending'. Al final del archivo se decide qué hacer con ellos.
-- ============================================================

-- ── sightings.moderation_status ───────────────────────────────────

SET @col_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sightings' AND COLUMN_NAME = 'moderation_status'
);
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE sightings ADD COLUMN moderation_status ENUM(''pending'',''approved'',''rejected'') NOT NULL DEFAULT ''pending'' AFTER archived_at',
  'SELECT "moderation_status ya existe, se omite" AS resultado'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sightings' AND COLUMN_NAME = 'moderated_at'
);
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE sightings ADD COLUMN moderated_at TIMESTAMP NULL DEFAULT NULL AFTER moderation_status',
  'SELECT "moderated_at ya existe, se omite" AS resultado'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ── sightings.likes_count ─────────────────────────────────────────
-- Contador desnormalizado: el feed devuelve hasta 50 filas y hacer un
-- COUNT(*) sobre sighting_likes por cada una sería un N+1 innecesario.
-- La fuente de verdad sigue siendo la tabla sighting_likes (con su
-- UNIQUE KEY); este número se recalcula desde ella en cada like/unlike,
-- dentro de la misma transacción, así que no puede desviarse.

SET @col_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sightings' AND COLUMN_NAME = 'likes_count'
);
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE sightings ADD COLUMN likes_count INT UNSIGNED NOT NULL DEFAULT 0 AFTER moderated_at',
  'SELECT "likes_count ya existe, se omite" AS resultado'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Índice del feed: filtra por estado + no archivado y ordena por fecha.

SET @idx_exists = (
  SELECT COUNT(*) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sightings' AND INDEX_NAME = 'idx_feed'
);
SET @sql = IF(@idx_exists = 0,
  'ALTER TABLE sightings ADD INDEX idx_feed (moderation_status, archived_at, created_at)',
  'SELECT "idx_feed ya existe, se omite" AS resultado'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ── users.is_moderator ────────────────────────────────────────────
-- No hay panel de administración dentro de la app infantil (no debe
-- haberlo). La moderación vive en backend/admin/moderation.php y este
-- flag es lo único que la protege, así que se activa a mano en la base:
--   UPDATE users SET is_moderator = 1 WHERE email = 'tu@email.com';

SET @col_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'is_moderator'
);
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE users ADD COLUMN is_moderator TINYINT(1) NOT NULL DEFAULT 0 AFTER level',
  'SELECT "is_moderator ya existe, se omite" AS resultado'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ── sighting_likes ────────────────────────────────────────────────
-- El UNIQUE KEY (sighting_id, user_id) es lo que hace que un corazón sea
-- un corazón por persona y no un contador de toques: pulsar dos veces no
-- suma dos, y no hace falta comprobarlo en PHP antes de insertar.

CREATE TABLE IF NOT EXISTS sighting_likes (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sighting_id INT UNSIGNED NOT NULL,
  user_id     INT UNSIGNED NOT NULL,
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_like (sighting_id, user_id),
  INDEX idx_sighting (sighting_id),
  FOREIGN KEY (sighting_id) REFERENCES sightings(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id)     REFERENCES users(id)     ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Qué hacer con lo que ya existe ────────────────────────────────
-- Los avistamientos anteriores a esta migración se quedan en 'pending' y
-- por tanto fuera del feed. Es lo correcto por defecto: nunca se publicó
-- contenido de nadie sin revisar, y aprobar en masa contenido que jamás
-- pasó por moderación sería exactamente lo que este cambio evita.
--
-- Si quieres revisarlos, aparecerán todos en backend/admin/moderation.php.
--
-- Si en cambio la base solo tiene datos de prueba tuyos y quieres verlos
-- ya en el feed, descomenta esta línea y ejecútala a conciencia:
--
-- UPDATE sightings SET moderation_status = 'approved', moderated_at = NOW()
--   WHERE moderation_status = 'pending';

-- Verificación rápida tras ejecutar:
-- DESCRIBE sightings;      -- debe listar moderation_status, moderated_at, likes_count
-- DESCRIBE sighting_likes; -- debe existir
-- SELECT moderation_status, COUNT(*) FROM sightings GROUP BY moderation_status;
