-- Tracks server-generated sighting uploads before they can be attached to a
-- sighting. Run after 08_2026_user_nickname.sql.
CREATE TABLE IF NOT EXISTS sighting_photo_uploads (
  id                    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id               INT UNSIGNED NOT NULL,
  filename              VARCHAR(64) NOT NULL UNIQUE,
  mime_type             VARCHAR(32) NOT NULL DEFAULT 'image/jpeg',
  attached_sighting_id  INT UNSIGNED NULL UNIQUE,
  created_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_upload_user (user_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (attached_sighting_id) REFERENCES sightings(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
