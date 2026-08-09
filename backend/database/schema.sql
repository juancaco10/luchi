-- ============================================================
-- Guardianes de las Luciérnagas — MySQL Schema
-- Compatible with MySQL 5.7+ / MariaDB 10.3+
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

-- ── Drop existing tables ──────────────────────────────────────────
DROP TABLE IF EXISTS login_attempts;
DROP TABLE IF EXISTS user_badges;
DROP TABLE IF EXISTS user_missions;
DROP TABLE IF EXISTS user_chapters;
DROP TABLE IF EXISTS sightings;
DROP TABLE IF EXISTS badges;
DROP TABLE IF EXISTS missions;
DROP TABLE IF EXISTS chapters;
DROP TABLE IF EXISTS users;

-- ── login_attempts ───────────────────────────────────────────────
CREATE TABLE login_attempts (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email        VARCHAR(191) NOT NULL,
  ip           VARCHAR(45)  NOT NULL,
  attempted_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_email_ip_time (email, ip, attempted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── users ─────────────────────────────────────────────────────────
-- password_hash es NULL para cuentas de Google (auth_provider='google');
-- google_sub es el 'sub' del token de Google, único por cuenta de Google.
CREATE TABLE users (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(100)        NOT NULL,
  email         VARCHAR(191)        NOT NULL UNIQUE,
  google_sub    VARCHAR(255)        NULL UNIQUE,
  auth_provider VARCHAR(20)         NOT NULL DEFAULT 'password',
  password_hash VARCHAR(255)        NULL,
  points        INT UNSIGNED        NOT NULL DEFAULT 0,
  -- Total absoluto de estrellas de minijuegos, tal como lo reporta el
  -- cliente vía PUT /me/game-progress (ver backend/api/routes/users.php).
  -- Es un total, no un incremento: reenviar el mismo valor no vuelve a
  -- sumar puntos.
  game_stars    INT UNSIGNED        NOT NULL DEFAULT 0,
  level         TINYINT UNSIGNED    NOT NULL DEFAULT 1,
  -- Acceso a backend/admin/moderation.php. Se activa a mano en la base;
  -- no hay forma de concedérselo a uno mismo desde la app.
  is_moderator  TINYINT(1)          NOT NULL DEFAULT 0,
  avatar_url    VARCHAR(500)        NULL,
  country       VARCHAR(100)        NULL,
  city          VARCHAR(120)        NULL,
  created_at    TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── chapters ──────────────────────────────────────────────────────
CREATE TABLE chapters (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  title         VARCHAR(200)        NOT NULL,
  description   TEXT                NOT NULL,
  video_url     VARCHAR(500)        NOT NULL,
  thumbnail_url VARCHAR(500)        NULL,
  order_index   TINYINT UNSIGNED    NOT NULL DEFAULT 1,
  points_reward SMALLINT UNSIGNED   NOT NULL DEFAULT 15,
  facts         JSON                NULL,      -- Array of fact strings
  quiz          JSON                NULL,      -- Array of {question, options[], correctIndex}
  is_active     TINYINT(1)          NOT NULL DEFAULT 1,
  created_at    TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_active_order (is_active, order_index)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── user_chapters ─────────────────────────────────────────────────
CREATE TABLE user_chapters (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id      INT UNSIGNED NOT NULL,
  chapter_id   INT UNSIGNED NOT NULL,
  completed_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_user_chapter (user_id, chapter_id),
  FOREIGN KEY (user_id)    REFERENCES users(id)    ON DELETE CASCADE,
  FOREIGN KEY (chapter_id) REFERENCES chapters(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── missions ──────────────────────────────────────────────────────
CREATE TABLE missions (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  title         VARCHAR(200)        NOT NULL,
  description   TEXT                NOT NULL,
  type          ENUM('daily','weekly') NOT NULL DEFAULT 'daily',
  points_reward SMALLINT UNSIGNED   NOT NULL DEFAULT 10,
  icon          VARCHAR(10)         NOT NULL DEFAULT '🎯',
  how_to        TEXT                NULL,
  tip           TEXT                NULL,
  is_active     TINYINT(1)          NOT NULL DEFAULT 1,
  created_at    TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_active_type (is_active, type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── user_missions ─────────────────────────────────────────────────
CREATE TABLE user_missions (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id      INT UNSIGNED NOT NULL,
  mission_id   INT UNSIGNED NOT NULL,
  completed_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_user_mission (user_id, mission_id),
  FOREIGN KEY (user_id)   REFERENCES users(id)   ON DELETE CASCADE,
  FOREIGN KEY (mission_id) REFERENCES missions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── sightings ────────────────────────────────────────────────────
CREATE TABLE sightings (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id       INT UNSIGNED     NOT NULL,
  lat           DECIMAL(10, 7)   NOT NULL,
  lng           DECIMAL(10, 7)   NOT NULL,
  quantity      SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  notes         TEXT             NULL,
  photo_url     VARCHAR(500)     NULL,
  location_name VARCHAR(300)     NULL,
  created_at    TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP        NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  archived_at   TIMESTAMP        NULL DEFAULT NULL,
  -- Moderación previa: nada aparece en el feed comunitario hasta que un
  -- moderador lo aprueba. Ver docs/PRIVACY.md — es la condición sin la
  -- cual `GET /sightings` no debe estar abierto en una app para menores.
  moderation_status ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  moderated_at  TIMESTAMP        NULL DEFAULT NULL,
  -- Contador desnormalizado de corazones; la verdad está en sighting_likes.
  likes_count   INT UNSIGNED     NOT NULL DEFAULT 0,
  INDEX idx_user   (user_id),
  INDEX idx_coords (lat, lng),
  INDEX idx_user_created (user_id, created_at),
  INDEX idx_feed (moderation_status, archived_at, created_at),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── sighting_likes ───────────────────────────────────────────────
-- Un corazón por persona y avistamiento: lo garantiza el UNIQUE KEY, no
-- una comprobación en PHP.
CREATE TABLE sighting_likes (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sighting_id INT UNSIGNED NOT NULL,
  user_id     INT UNSIGNED NOT NULL,
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_like (sighting_id, user_id),
  INDEX idx_sighting (sighting_id),
  FOREIGN KEY (sighting_id) REFERENCES sightings(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id)     REFERENCES users(id)     ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── badges ───────────────────────────────────────────────────────
CREATE TABLE badges (
  id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name              VARCHAR(100) NOT NULL,
  emoji             VARCHAR(10)  NOT NULL,
  description       TEXT         NOT NULL,
  condition_type    ENUM('points','missions','chapters','sightings','game_stars') NOT NULL,
  condition_value   INT UNSIGNED NOT NULL,
  created_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── user_badges ──────────────────────────────────────────────────
CREATE TABLE user_badges (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id    INT UNSIGNED NOT NULL,
  badge_id   INT UNSIGNED NOT NULL,
  earned_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_user_badge (user_id, badge_id),
  FOREIGN KEY (user_id)  REFERENCES users(id)  ON DELETE CASCADE,
  FOREIGN KEY (badge_id) REFERENCES badges(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- Seed Data
-- ============================================================

-- Chapters
INSERT INTO chapters (title, description, video_url, order_index, points_reward, facts, quiz) VALUES
('¿Qué es una luciérnaga?',
 'Descubre los secretos de estos increíbles insectos bioluminiscentes que iluminan las noches de verano.',
 'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4',
 1, 15,
 '["Las luciérnagas producen luz fría — casi sin calor.", "Su luz es producida por una reacción química llamada bioluminiscencia.", "Existen más de 2000 especies de luciérnagas en el mundo."]',
 '[{"question": "¿Cómo producen luz las luciérnagas?", "options": ["Con electricidad", "Con bioluminiscencia", "Con el sol", "Con calor"], "correctIndex": 1}]'),

('Su hábitat natural',
 'Aprende dónde viven las luciérnagas y por qué necesitan lugares oscuros y húmedos para sobrevivir.',
 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
 2, 15,
 '["Las luciérnagas prefieren zonas húmedas como prados y bordes de ríos.", "La contaminación lumínica es su mayor amenaza.", "Necesitan vegetación para esconderse durante el día."]',
 '[{"question": "¿Cuál es la mayor amenaza para las luciérnagas?", "options": ["El frío", "La contaminación lumínica", "La lluvia", "El viento"], "correctIndex": 1}]'),

('Por qué están desapareciendo',
 'Entiende las causas del declive de las luciérnagas y cómo cada uno de nosotros puede hacer la diferencia.',
 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
 3, 20,
 '["La pérdida de hábitat afecta al 70% de las especies.", "El uso de pesticidas mata a sus larvas que viven en la tierra.", "Puedes ayudar apagando luces exteriores innecesarias."]',
 '[{"question": "¿Qué puedes hacer para ayudar?", "options": ["Usar más luces afuera", "Apagar luces innecesarias", "Usar pesticidas", "Nada"], "correctIndex": 1}]'),

('Cómo ser un Guardián',
 'Aprende las acciones concretas que puedes tomar para proteger a las luciérnagas en tu vecindario.',
 'https://download.samplelib.com/mp4/sample-15s.mp4',
 4, 25,
 '["Planta vegetación nativa para crear hábitat.", "Evita pesticidas y herbicidas en tu jardín.", "Registra tus avistamientos para ayudar a los científicos."]',
 '[{"question": "¿Qué deberías plantar para ayudar?", "options": ["Plantas artificiales", "Vegetación nativa", "Cactus", "Ninguna"], "correctIndex": 1}]');

-- Missions
INSERT INTO missions (title, description, type, points_reward, icon, how_to, tip) VALUES
('Apaga luces innecesarias', 'Durante la noche de hoy, apaga todas las luces exteriores que no necesites.', 'daily', 10, '💡',
 'Cuando anochezca, recorre tu casa y apaga las luces del jardín, porche o terraza que no estés usando.',
 'La contaminación lumínica es la principal amenaza para las luciérnagas. ¡Cada luz apagada cuenta!'),

('Observa la naturaleza 5 min', 'Siéntate afuera o cerca de una ventana y observa la naturaleza por 5 minutos.', 'daily', 10, '🌿',
 'Busca un lugar tranquilo. Presta atención a insectos, plantas y sonidos.',
 'La observación consciente nos conecta con la naturaleza y nos hace mejores guardianes.'),

('Lee un dato sobre luciérnagas', 'Aprende un dato nuevo sobre las luciérnagas y cuéntaselo a alguien.', 'daily', 10, '📚',
 'Ve a la sección de Capítulos y lee al menos un hecho de cualquier capítulo.',
 'Compartir conocimiento es una forma de proteger: cuantas más personas sepan, mejor.'),

('Semana sin pesticidas', 'Compromete a tu familia a no usar pesticidas durante esta semana.', 'weekly', 30, '🌱',
 'Habla con tu familia sobre el daño que los pesticidas causan a insectos benéficos.',
 'Las larvas de luciérnaga viven en la tierra. Los pesticidas las matan antes de que puedan convertirse en adultos.'),

('Planta algo nativo', 'Planta una semilla o plántula de especie nativa de tu región.', 'weekly', 30, '🌻',
 'Visita un vivero local o usa semillas de plantas que ya crecen en tu zona.',
 'Las plantas nativas proveen el hábitat perfecto para las luciérnagas y otros insectos benéficos.'),

('Registra un avistamiento', 'Sal al anochecer y registra si ves (o no) luciérnagas en tu zona.', 'weekly', 30, '✨',
 'Espera que oscurezca y observa durante al menos 15 minutos.',
 'Incluso reportar que NO viste luciérnagas es información valiosa para los científicos.');

-- Badges
INSERT INTO badges (name, emoji, description, condition_type, condition_value) VALUES
('Primer Paso', '📖', 'Completa tu primer capítulo', 'chapters', 1),
('Explorador', '🔭', 'Alcanza 100 puntos', 'points', 100),
('Guardián', '🛡️', 'Alcanza 200 puntos', 'points', 200),
('Maestro Guardián', '⭐', 'Alcanza 400 puntos', 'points', 400),
('Observador Nocturno', '🌙', 'Registra tu primer avistamiento', 'sightings', 1),
('Pequeño Científico', '🧪', 'Completa todos los capítulos', 'chapters', 4),
('Primera Estrella', '🌟', 'Gana tu primera estrella en un minijuego', 'game_stars', 1),
('Jugador Constante', '🎮', 'Reúne 25 estrellas en los minijuegos', 'game_stars', 25),
('Estrella del Bosque', '🏅', 'Reúne 75 estrellas en los minijuegos', 'game_stars', 75),
('Leyenda Luminosa', '🏆', 'Consigue las 150 estrellas: todos los juegos, todos los niveles, perfectos', 'game_stars', 150);
