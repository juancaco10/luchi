-- ============================================================
-- Añade login con Google a `users`.
--
-- Ejecutar UNA vez en phpMyAdmin (u otro cliente MySQL) contra la base de
-- producción. Seguro de re-ejecutar: cada sentencia comprueba primero si
-- ya se aplicó, así que correrla dos veces por error no falla ni duplica.
--
-- Después de esta migración, un usuario que se registró con contraseña
-- sigue teniendo password_hash relleno y auth_provider='password'; nada
-- cambia para las cuentas existentes.
-- ============================================================

-- password_hash pasa a admitir NULL: las cuentas de Google no tienen
-- contraseña. Sin este cambio, INSERT de un usuario de Google fallaría
-- por violar NOT NULL.
ALTER TABLE users MODIFY password_hash VARCHAR(255) NULL;

-- google_sub: el 'sub' (identificador estable) del token de Google.
-- UNIQUE evita que dos cuentas se vinculen a la misma cuenta de Google.
SET @col_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'google_sub'
);
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE users ADD COLUMN google_sub VARCHAR(255) NULL UNIQUE AFTER email',
  'SELECT "google_sub ya existe, se omite" AS resultado'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- auth_provider: 'password' | 'google'. Sirve para decidir en el cliente
-- si mostrar el formulario de contraseña o no, y para diagnóstico.
SET @col_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'auth_provider'
);
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE users ADD COLUMN auth_provider VARCHAR(20) NOT NULL DEFAULT ''password'' AFTER google_sub',
  'SELECT "auth_provider ya existe, se omite" AS resultado'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Verificación rápida tras ejecutar: debe listar name, email, google_sub,
-- auth_provider, password_hash. Las filas existentes deben mostrar
-- auth_provider='password' y google_sub=NULL.
-- DESCRIBE users;
