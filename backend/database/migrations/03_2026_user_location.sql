-- ============================================================
-- Añade país y ciudad a `users` — se piden una vez, la primera vez que el
-- usuario va a publicar un avistamiento, y quedan guardados en el perfil
-- para no volver a preguntarlos.
--
-- Ejecutar UNA vez en phpMyAdmin (u otro cliente MySQL) contra la base de
-- producción. Seguro de re-ejecutar: cada sentencia comprueba primero si
-- ya se aplicó, así que correrla dos veces por error no falla ni duplica.
-- ============================================================

SET @col_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'country'
);
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE users ADD COLUMN country VARCHAR(100) NULL AFTER avatar_url',
  'SELECT "country ya existe, se omite" AS resultado'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'city'
);
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE users ADD COLUMN city VARCHAR(120) NULL AFTER country',
  'SELECT "city ya existe, se omite" AS resultado'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Verificación rápida tras ejecutar: debe listar country y city como NULL
-- en todas las filas existentes.
-- DESCRIBE users;
