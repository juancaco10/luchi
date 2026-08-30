-- Technical consent record only. Legal review determines whether this method
-- is sufficient for each market before enabling a public child release.
ALTER TABLE users
  ADD COLUMN parental_consent_status TINYINT(1) NOT NULL DEFAULT 0 AFTER nickname,
  ADD COLUMN parental_consent_at DATETIME NULL DEFAULT NULL AFTER parental_consent_status,
  ADD COLUMN parental_consent_policy_version VARCHAR(64) NULL DEFAULT NULL AFTER parental_consent_at,
  ADD COLUMN parental_consent_method VARCHAR(32) NULL DEFAULT NULL AFTER parental_consent_policy_version;
