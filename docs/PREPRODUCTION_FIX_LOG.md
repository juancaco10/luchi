# Preproduction Fix Log

Last updated: 2026-08-25

## SAFE-001 / SAFE-002

| Field | Evidence |
| --- | --- |
| Status | Implemented; backend integration test still required. |
| Files | `backend/api/routes/sightings.php` |
| Change | New sightings are server-created as `pending`; public feed is disabled by default unless the server explicitly defines `PUBLIC_SIGHTINGS_ENABLED=true`. |
| Reason | A regular user must not self-publish child-generated content by modifying a client request. |
| Verification | `php -l backend/api/routes/sightings.php` passed. |

## SAFE-003

| Field | Evidence |
| --- | --- |
| Status | Implemented; backend integration test still required. |
| Files | `backend/api/routes/uploads.php`, `backend/api/routes/sightings.php`, `backend/database/schema*.sql`, `backend/database/migrations/09_2026_sighting_photo_uploads.sql` |
| Change | Uploads are recorded with owner and attachment state. Create/edit accept only a generated JPEG filename recorded for the authenticated user. |
| Reason | Prevent arbitrary remote URLs and ownership bypasses in community/private sightings. |
| Verification | PHP syntax checks passed. A clean database must apply migration 09 before deployment. |

## Safe Launch Client Controls

| Field | Evidence |
| --- | --- |
| Status | Implemented. |
| Files | `lib/core/utils/constants.dart`, `lib/app.dart`, `lib/widgets/ad_banner.dart`, `lib/main.dart`, `lib/features/home/widgets/home_bottom_nav.dart`, `lib/features/sightings/screens/sighting_form_screen.dart` |
| Change | Community routes/nav, precise GPS usage, and ads default to disabled. |
| Reason | These features remain unavailable until policy, operations, and release configuration are verified. |
| Verification | Dart formatting passed. Full Flutter analysis did not finish in this environment and remains required. |

## REL-001

| Field | Evidence |
| --- | --- |
| Status | Implemented; release keystore is required to validate. |
| Files | `android/app/build.gradle.kts` |
| Change | A release build now fails with an explicit message if `android/key.properties` is absent. |
| Reason | Prevent debug-signed AAB artifacts from being mistaken for store releases. |
| Verification | A signed build cannot be executed without the user-managed release keystore. |

## PRIV-002 / QA-001

| Field | Evidence |
| --- | --- |
| Status | Partially implemented; legal/account binding and automated verification remain open. |
| Files | `lib/core/storage/local_storage.dart`, `lib/features/auth/screens/onboarding_screen.dart`, `lib/features/auth/screens/parental_consent_screen.dart`, `lib/app.dart`, `lib/features/auth/providers/auth_provider.dart` |
| Change | Onboarding completes only after consent is recorded with UTC timestamp and policy version. Local point updates no longer require initialized storage in tests. |
| Reason | Prevent a transient consent checkbox and remove the known `LocalStorage._prefs` initialization exception. |
| Verification | Dart formatting passed. The targeted Flutter test runner stalled in this environment before completion; the test is not marked passed. |

## PRIV-002 backend record

| Field | Evidence |
| --- | --- |
| Status | Implemented; legal sufficiency and integration test remain open. |
| Files | `backend/api/routes/users.php`, `backend/database/migrations/10_2026_parental_consent.sql`, schema files, auth provider and local storage |
| Change | New password, Google, and guest accounts require and store consent status, timestamp, policy version, and method. |
| Verification | `php -l backend/api/routes/users.php` passed. |

## QA runner investigation

| Field | Evidence |
| --- | --- |
| Status | Open environment issue. |
| Change | Added initialization guards to `AuthNotifier._checkSession()` and game-star sync so tests do not access storage or network before bootstrap. |
| Result | `flutter test test/games_progress_test.dart --reporter expanded` consistently stalls after loading the test file and was cancelled; it did not reach a result or emit the prior initialization exception. |
