-- ============================================================
-- Añade edición/archivado a `sightings`: updated_at, archived_at y un
-- índice (user_id, created_at) para listar/filtrar por fecha.
--
-- Ejecutar UNA vez en phpMyAdmin (u otro cliente MySQL) contra la base de
-- producción. Seguro de re-ejecutar: cada sentencia comprueba primero si
-- ya se aplicó, así que correrla dos veces por error no falla ni duplica.
--
-- archived_at es NULL = activo, con fecha = archivado (no un booleano):
-- así queda registrado también cuándo se archivó. No hay borrado real —
-- los avistamientos otorgan puntos que nunca se restan, así que "archivar"
-- (ocultar sin eliminar la fila) evita que crear→borrar→crear sirva para
-- farmear puntos indefinidamente.
-- ============================================================

SET @col_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sightings' AND COLUMN_NAME = 'updated_at'
);
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE sightings ADD COLUMN updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP AFTER created_at',
  'SELECT "updated_at ya existe, se omite" AS resultado'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sightings' AND COLUMN_NAME = 'archived_at'
);
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE sightings ADD COLUMN archived_at TIMESTAMP NULL DEFAULT NULL AFTER updated_at',
  'SELECT "archived_at ya existe, se omite" AS resultado'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists = (
  SELECT COUNT(*) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sightings' AND INDEX_NAME = 'idx_user_created'
);
SET @sql = IF(@idx_exists = 0,
  'ALTER TABLE sightings ADD INDEX idx_user_created (user_id, created_at)',
  'SELECT "idx_user_created ya existe, se omite" AS resultado'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Verificación rápida tras ejecutar: debe listar updated_at y archived_at
-- como NULL en todas las filas existentes.
-- DESCRIBE sightings;
