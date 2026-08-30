# Preproduction Audit

Last updated: 2026-08-25

Status: discovery and initial inventory completed. No functional code changes applied in this phase.

Phase 2 update (2026-08-25): Safe Launch code changes are in progress. See
`docs/PREPRODUCTION_FIX_LOG.md`; legal consent, policy review, real-device,
backend integration, and signed-release verification are not yet complete.

## Scope completed in this pass

- Repository structure inspection
- Flutter architecture inspection
- GoRouter route inventory
- Provider/state inventory
- Local storage and sync inspection
- Backend API route inventory
- Android manifest/build configuration inspection
- Dependency inventory from `pubspec.yaml`
- Search for TODO/FIXME/mock/placeholder indicators
- Initial automated verification with `flutter analyze` and `flutter test`

## Repository Reality Check

The codebase is a Flutter client plus a PHP/MySQL backend and a lightweight web landing page. The source of truth does not match all narrative docs:

- The app does have real backend routes for email auth, Google auth, guest auth, profile, chapters, badges, sightings, uploads and game-progress sync.
- The app also still contains mock/seed pathways for auth and chapter seed content, but they are compile-time gated and default to disabled.
- Community/social sightings are active in code and backend, not merely planned.
- The README is stale in several important areas and should not be treated as authoritative for release readiness.

## Detected Architecture

### Client

- Framework: Flutter / Dart
- State: Riverpod `StateNotifierProvider`, `Provider`, `FutureProvider`
- Navigation: `GoRouter` with `StatefulShellRoute.indexedStack`
- Networking: `dio`
- Storage:
  - `flutter_secure_storage` for auth token
  - `SharedPreferences` for onboarding, cached user snapshot, active user pointer, first-game flags
  - `Hive` for namespaced per-user caches and offline queues
- Sync/offline:
  - offline queue for sightings in Hive
  - `SyncService` listens to connectivity and retries pending uploads
- Maps/location/media:
  - `flutter_map`
  - `geolocator`
  - `geocoding`
  - `image_picker`
  - `video_player` + `chewie`
- Auth:
  - email/password
  - Google Sign-In (`google_sign_in`)
  - guest login
- Monetization:
  - `google_mobile_ads` banner
- Games:
  - local-authoritative minigame progress in Hive
  - server sync via absolute star total to `/me/game-progress`

### Backend

- PHP 8.x REST API under `backend/api`
- MySQL schema and migrations under `backend/database`
- Custom JWT HS256 auth in `backend/api/middleware/auth.php`
- Routes split by module:
  - `users.php`
  - `chapters.php`
  - `sightings.php`
  - `uploads.php`
  - `badges.php`
- Admin moderation UI: `backend/admin/moderation.php`

## Inventory

### Screens and navigation

See [SCREEN_INVENTORY.md](D:/Mis-Juegos-git-2026/app_luchi_luciernagas/docs/SCREEN_INVENTORY.md).

### Providers detected

| Provider | File | Purpose |
| --- | --- | --- |
| `routerProvider` | `lib/app.dart` | Root router with redirects/guards |
| `themeProvider` | `lib/core/theme/theme_provider.dart` | Light/dark theme |
| `syncServiceProvider` | `lib/core/network/sync_service.dart` | Connectivity-based offline sync |
| `dioProvider` / `apiClientProvider` | `lib/core/network/api_client.dart` | HTTP client |
| `authProvider` / `currentUserProvider` | `lib/features/auth/providers/auth_provider.dart` | Session and current user |
| `chaptersProvider` / `chapterByIdProvider` | `lib/features/education/providers/chapters_provider.dart` | Chapters and lookup |
| `gamesProgressProvider` / `gameProgressProvider` | `lib/features/games/providers/games_progress_provider.dart` | Local game progress |
| `sightingsProvider` / `sightingByIdProvider` | `lib/features/sightings/providers/sightings_provider.dart` | Own feed, community feed, submit/edit/archive/like/upload |
| `profileProvider` / `badgesProvider` | `lib/features/profile/providers/profile_provider.dart` | Profile proxy + badges |
| `packageInfoProvider` | `lib/features/profile/screens/settings_screen.dart` | App version info |

### Services and storage

| Component | File | Notes |
| --- | --- | --- |
| `LocalStorage` | `lib/core/storage/local_storage.dart` | Secure token, SharedPreferences snapshot, namespaced Hive boxes |
| `SyncService` | `lib/core/network/sync_service.dart` | Drains pending sightings on startup/connectivity |
| `GoogleAuthService` | `lib/features/auth/data/google_auth_service.dart` | Abstracts platform-specific Google flow |
| `ApiClient` | `lib/core/network/api_client.dart` | Injects bearer token, logging, error mapping |
| `cached_list_repository.dart` | `lib/core/data/cached_list_repository.dart` | Shared stale-cache loading pattern |

### Hive / SharedPreferences / secure storage

- Secure storage:
  - `auth_token`
- SharedPreferences:
  - `current_user`
  - `onboarding_done`
  - `active_user_id`
  - first-game flags per game/user
- Hive boxes:
  - `chapters_box`
  - `sightings_box`
  - `games_box`
  - `badges_box`
  - `feed_box`
- Namespacing:
  - boxes are suffixed `_u<userId>` after login

### Backend endpoints detected

| Method | Endpoint | Module |
| --- | --- | --- |
| `POST` | `/register` | users |
| `POST` | `/login` | users |
| `POST` | `/auth/google` | users |
| `POST` | `/auth/guest` | users |
| `GET` | `/me` | users |
| `PUT` | `/me` | users |
| `PUT` | `/me/game-progress` | users |
| `DELETE` | `/me` | users |
| `GET` | `/chapters` | chapters |
| `POST` | `/complete-chapter` | chapters |
| `GET` | `/badges` | badges |
| `POST` | `/sightings` | sightings |
| `GET` | `/sightings` | sightings/community |
| `GET` | `/my-sightings` | sightings |
| `PUT` | `/sightings/{id}` | sightings |
| `POST` | `/sightings/{id}/archive` | sightings |
| `POST` | `/sightings/{id}/like` | sightings |
| `DELETE` | `/sightings/{id}/like` | sightings |
| `GET` | `/moderation/queue` | sightings |
| `POST` | `/sightings/{id}/moderate` | sightings |
| `POST` | `/uploads/sighting-photo` | uploads |

### Android permissions and release config detected

Source: `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts`

- Declared permissions:
  - `INTERNET`
  - `ACCESS_FINE_LOCATION`
  - `ACCESS_COARSE_LOCATION`
  - `CAMERA`
- Explicitly removed merged permissions:
  - `WRITE_EXTERNAL_STORAGE`
  - `READ_EXTERNAL_STORAGE`
  - `READ_PHONE_STATE`
- Activity config:
  - portrait only
  - `adjustResize`
- Ads:
  - AdMob application meta-data present
- Build:
  - `minSdk` forced to at least 26
  - release signing falls back to debug keystore if `android/key.properties` is absent
  - release minify/shrink enabled

### Dependencies considered critical for release

- `flutter_riverpod`
- `go_router`
- `dio`
- `hive` / `hive_flutter`
- `shared_preferences`
- `flutter_secure_storage`
- `google_sign_in`
- `google_mobile_ads`
- `flutter_map`
- `geolocator`
- `geocoding`
- `image_picker`
- `video_player`
- `chewie`
- `nsfw_detector_flutter`
- `connectivity_plus`
- `package_info_plus`

## Mock / TODO / Placeholder Findings

### Confirmed mock or seed behavior

- `AppConstants.useMockAuth` exists but defaults to `false`.
- `AppConstants.allowSeedData` exists but defaults to `false`.
- `AuthNotifier` still contains `_mockLogin` and `_mockRegister`.
- `ChapterModel.getMockChapters()` still points to public sample video URLs.

### Confirmed TODO / incomplete behavior

- Login screen still exposes "forgot password" as UI-only with TODO comment; no backend recovery endpoint exists.
- Existing docs include stale claims about backend/auth state.

### Placeholder or production-risk content

- Seeded chapter videos in schema and mock data still use sample/public URLs:
  - `interactive-examples.mdn.mozilla.net`
  - `flutter.github.io`
  - `download.samplelib.com`
- iOS ad unit remains Google test banner ID.
- Android README instructions are stale and conflict with current code.

## Automated Verification

Executed on 2026-08-25 from workspace root.

### `flutter analyze`

Result: PASS with warnings/info, no blocking compile errors

Key findings:

- 28 issues reported
- 3 warnings of note:
  - `lib/core/network/sync_service.dart`: unnecessary type check / connectivity API mismatch pattern
  - unused import in `parental_consent_screen.dart`
  - unused imports in some tests
- multiple deprecations in onboarding/settings/tests

Interpretation:

- The app is analyzable and currently compiles at analysis level.
- The warnings are not release blockers by themselves, but some indicate maintenance drift.

### `flutter test`

Result: PASS

Important observation:

- Tests pass, but execution logs reveal `LateInitializationError` from `LocalStorage._prefs` when `GamesProgressNotifier.recordResult()` reaches `authProvider` in test contexts without full storage init.
- The exception is currently swallowed by gameplay reward logic and does not fail the suite.

Interpretation:

- Test suite coverage exists but is narrow.
- There is hidden initialization coupling between game progress and auth/local storage that should be audited further.

### `flutter build appbundle --release`

Result: INCONCLUSIVE in this environment.

- The command entered Gradle's `bundleRelease` task and produced no success or
  failure output after several minutes, so it was cancelled without changing
  source configuration.
- An AAB already exists at `build/app/outputs/bundle/release/app-release.aab`,
  but its timestamp predates this run; it must not be treated as evidence that
  the current worktree builds or is correctly signed.
- `android/key.properties` is absent from the workspace. Per
  `android/app/build.gradle.kts`, any eventual release build will fall back to
  the debug keystore unless a real release keystore is supplied.

## Initial Severity Assessment

This section is intentionally conservative. Items stay here until disproven by deeper verification.

### Initial P0 candidates

None confirmed yet from this pass.

### Initial P1 candidates

| ID | Area | Finding | Why it is high risk |
| --- | --- | --- | --- |
| REL-001 | Release / signing | Release build currently falls back to debug keystore when `android/key.properties` is absent. | A store-ready release cannot ship with debug signing; must be verified before publish. |
| PRIV-001 | Child privacy | Community feed and map are active surfaces in a child-oriented app. Privacy controls exist in code/docs, but end-to-end verification is still incomplete. | Minor-location and user-generated content exposure risk is potentially release-critical. |
| EDU-001 | Content readiness | Chapters and seeded DB content still reference sample/public video URLs. | Educational production content is not fully validated; could expose non-product media. |
| UX-001 | Auth recovery | Login exposes password-recovery affordance but no real reset flow exists. | Important preproduction gap for real accounts and support burden. |
| DOC-001 | Operational docs | README contradicts current implementation and still describes outdated/mock states. | High risk for incorrect deployment, QA, and release operations. |

### Initial P2 candidates

| ID | Area | Finding |
| --- | --- | --- |
| QA-001 | Tests | Passing tests still emit runtime initialization errors in logs. |
| TECH-001 | Tooling drift | Deprecated APIs and warning-level issues present in analyze output. |
| ADS-001 | Monetization | Android manifest has App ID meta-data, Android banner unit is real-looking, iOS banner remains test ID. Release ad setup is mixed and needs explicit verification. |
| PERF-001 | Splash | Startup is fixed-delay driven instead of readiness-driven. |
| NAV-001 | Settings | Settings surface is materially narrower than product expectations in the audit brief. |

## Initial Risks to Carry Into Deep Audit

- Child privacy and location exposure across community surfaces
- Release signing and Google Play readiness
- Real Google Sign-In release readiness due to absence of visible `google-services.json` / `GoogleService-Info.plist` in repo
- Placeholder educational content in chapters/videos
- Hidden state coupling between auth, local storage and minigame progress
- README / operational-document drift
- Need to verify actual AAB release build, not only analyze/test

## Deep Audit: Child Safety, Community, and Consent

Verified on 2026-08-25 by static inspection. These findings supersede the
earlier unconfirmed privacy candidate where applicable.

### Confirmed release blockers (P0)

| ID | Evidence | Finding | Required disposition before public release |
| --- | --- | --- | --- |
| SAFE-001 | `backend/api/routes/sightings.php:91-109`, `:158-215` | Every new sighting is inserted as `approved` and is immediately returned to every authenticated user. The payload can include free-form notes and a photo. | Disable the public feed/map, or restore server-enforced pending moderation with staffed review, reporting/escalation, and test coverage. Do not rely on client-side filtering. |
| SAFE-002 | `lib/features/sightings/utils/nsfw_filter.dart:14-26` | The only content filter is client-side and fails open: classifier errors and null results are accepted. A modified client bypasses it entirely. | Make the backend authoritative for publication safety. Until a verified moderation workflow exists, retain all user content as private/pending. |
| SAFE-003 | `backend/api/routes/sightings.php:74-76`, `:95-109`, `:325-330`, `:359-374`; `lib/features/sightings/widgets/feed_post_card.dart:158-164` | `photo_url` accepts arbitrary text and the feed renders it with `Image.network`. A malicious account can make children's devices retrieve a third-party URL, bypassing the upload pipeline and its EXIF/type controls. | Accept only server-owned upload paths that are bound to the authenticated uploader, or remove remote photo rendering from community content. Validate the same rule on create and edit. |
| PRIV-002 | `lib/features/auth/screens/onboarding_screen.dart:69-73`; `lib/features/auth/screens/parental_consent_screen.dart:19-24`; `lib/app.dart:179-198` | Onboarding is marked completed before the consent screen. Consent is an in-memory checkbox that only navigates to login; it is neither persisted nor associated with an account, date, policy version, nor verified by the API. | Define the legal consent model with counsel, implement durable/verifiable consent before account creation or collection, and block protected features server-side until it is present. |
| ADS-002 | `lib/main.dart:31-34`; `lib/widgets/ad_banner.dart:30-42` | A child-directed app initializes AdMob and submits a default `AdRequest`; no child-directed or under-age request configuration is set in the app. Banners appear throughout the shell and on location setup. | Obtain the applicable ad/child-privacy decision, configure the SDK accordingly, validate inventory and store declarations, or remove ads for launch. |

### Confirmed high-priority findings (P1)

| ID | Evidence | Finding | Required disposition before broad release |
| --- | --- | --- | --- |
| PRIV-003 | `lib/features/sightings/screens/sighting_form_screen.dart:44-45`, `:87-115`, `:706-739` | Exact-location sharing is enabled by default. The first submit can request GPS and persist an approximately 100 m coordinate, which is then public in the community map/feed after server rounding. | Default to no precise location, require an affirmative per-sighting choice, and reassess whether 100 m is sufficiently protective for children. |
| PRIV-004 | `backend/api/routes/sightings.php:74-76`, `:165-215`; `lib/features/sightings/screens/sighting_form_screen.dart:484-494` | Notes have no client or server length/content policy and are immediately visible to other children. `sanitize()` strips tags but does not moderate abusive, identifying, or contact content. | Add server-side length/rate limits and moderation; do not publish free-form text before the P0 moderation decision is resolved. |
| PRIV-005 | `backend/api/privacidad.html:21-39`; `docs/PRIVACY.md:26-29`, `:58-68` | The public policy and internal privacy document contain stale and contradictory claims, including that consent and secure token storage are absent although code has partial implementations. | Publish a counsel-reviewed policy that matches production behavior and replace stale internal checklist assertions before store submission. |
| REL-002 | `backend/database/schema.sql:33-56`; `backend/database/migrations/08_2026_user_nickname.sql:1-6`; `backend/database/schema_install.sql` | The canonical fresh schema does not include `users.nickname`, while runtime API selects it. Migration 08 is a new untracked change and the install schema must be kept in sync. | Validate the exact migration order on a clean database and make fresh-install schema match the deployed runtime contract. |
| ADS-003 | `android/app/src/main/AndroidManifest.xml:65-71`; `lib/core/utils/constants.dart:190-191`; `ios/Runner/Info.plist:29-32` | Ad configuration is inconsistent: Android manifest comments label its App ID as test, Android banner is production-looking, and iOS banner uses Google's test unit. | Complete platform-specific ad configuration and verify with the intended store release build. |

### Verified mitigations, with limits

- Authentication tokens are now read from `flutter_secure_storage`; the stale plaintext-token claim in `docs/PRIVACY.md` is documentation drift, not a confirmed current code defect.
- Photo uploads verify MIME type and re-encode server-side in `backend/api/routes/uploads.php`, which strips EXIF. This mitigation applies only when the client uses the upload endpoint; it does not constrain arbitrary `photo_url` values accepted by sighting create/edit.
- Community responses round coordinates to three decimals and reduce `location_name` to city level in `backend/api/routes/sightings.php`. The rounding reduces precision but does not remove the need for a child-location safety decision.
- Account deletion removes user rows and associated uploads in the current backend implementation. Its deployed behavior and backup/retention policy are still unverified.

## Files and Docs Created / Updated in This Pass

- Created: [SCREEN_INVENTORY.md](D:/Mis-Juegos-git-2026/app_luchi_luciernagas/docs/SCREEN_INVENTORY.md)
- Created: [PREPRODUCTION_AUDIT.md](D:/Mis-Juegos-git-2026/app_luchi_luciernagas/docs/PREPRODUCTION_AUDIT.md)
- Reused as existing evidence:
  - [BACKEND_AUDIT.md](D:/Mis-Juegos-git-2026/app_luchi_luciernagas/docs/BACKEND_AUDIT.md)
  - [PRIVACY.md](D:/Mis-Juegos-git-2026/app_luchi_luciernagas/docs/PRIVACY.md)

## Not Verified Yet

- A completed `flutter build appbundle --release` with a verified release signature
- Real Android device behavior for camera/GPS/background
- Google Sign-In release config on Android
- Tile provider policy compliance under expected production traffic
- PHP backend deployed behavior against real DB and uploads filesystem
- Full screen-by-screen empty/loading/error/offline states
- Accessibility, text scaling and responsive breakpoints in practice
