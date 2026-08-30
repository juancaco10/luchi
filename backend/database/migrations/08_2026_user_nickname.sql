-- Apodo corto del usuario: cómo quiere que lo llamen en el feed
-- comunitario y en la app (decisión de producto, 2026-08). Máximo 12
-- caracteres para que quepa en las tarjetas de avistamientos. NULL hasta
-- que el usuario lo elija (la app lo pide tras el primer login); mientras
-- tanto el feed muestra el primer nombre como fallback.
ALTER TABLE users ADD COLUMN nickname VARCHAR(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL;
