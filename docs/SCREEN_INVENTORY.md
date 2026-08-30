# Screen Inventory

Last updated: 2026-08-25

Scope: inventory derived from `lib/app.dart`, feature screen files under `lib/features/**/screens/`, and the widgets/screens they directly compose.

## Summary

- Total routed screens detected: 17
- Shell tabs (`StatefulShellRoute.indexedStack`): 5
- Out-of-shell routed screens: 12
- Non-routed UI surfaces with product impact: `SightingDetailsModal`, `AvatarPickerSheet`, delete-account sheets, nickname sheet
- Primary navigation source: [lib/app.dart](D:/Mis-Juegos-git-2026/app_luchi_luciernagas/lib/app.dart)

## Route Inventory

| Screen | File | Route | Feature | Auth | Initial state | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| SplashScreen | `lib/features/auth/screens/splash_screen.dart` | `/splash` | Auth bootstrap | No | Mejorable | Fixed 3200 ms delay before navigation; checks `LocalStorage` directly. |
| OnboardingScreen | `lib/features/auth/screens/onboarding_screen.dart` | `/onboarding` | Onboarding | No | Mejorable | Present, but child/privacy release readiness still needs deeper audit. |
| ParentalConsentScreen | `lib/features/auth/screens/parental_consent_screen.dart` | `/onboarding/consent` | Consent | No | Mejorable | Exists, but privacy documentation says consent is still release-blocking until fully verified. |
| LoginScreen | `lib/features/auth/screens/login_screen.dart` | `/login` | Auth | No | Mejorable | Email, password, Google, guest access. "Forgot password" is UI-only. |
| RegisterScreen | `lib/features/auth/screens/register_screen.dart` | `/register` | Auth | No | Mejorable | Real backend route exists. Needs full validation/error-state audit. |
| HomeScreen | `lib/features/home/screens/home_screen.dart` | `/home` | Dashboard | Yes | Mejorable | Uses current user, chapters, sightings feed, gamification widgets. |
| ChaptersListScreen | `lib/features/education/screens/chapters_list_screen.dart` | `/chapters` | Education | Yes | Mejorable | Backed by cached list repository + local cache. |
| ChapterDetailScreen | `lib/features/education/screens/chapter_detail_screen.dart` | `/chapters/:id` | Education | Yes | Mejorable | Completes chapter, video playback, unlock flow. Placeholder/seed video risk exists. |
| MapHubScreen | `lib/features/games/screens/map_hub_screen.dart` | `/game` | Games hub | Yes | Mejorable | Reads local game progress and auth profile state. |
| LevelSelectScreen | `lib/features/games/screens/level_select_screen.dart` | `/game/:gameId` | Games | Yes | Mejorable | Driven by `gameProgressProvider`. |
| QuizGameScreen / GuideGameScreen / SyncGameScreen / ProtectGameScreen / RestoreGameScreen | `lib/features/games/screens/*` | `/game/:gameId/play/:level` | Games runtime | Yes | Mejorable | Single dispatcher route mounts 5 different gameplay screens. |
| MapScreen | `lib/features/sightings/screens/map_screen.dart` | `/map` | Sightings/community | Yes | Mejorable | Uses `flutter_map`; community feed source. Needs tile/policy/perf audit. |
| CommunityFeedScreen | `lib/features/sightings/screens/community_feed_screen.dart` | `/feed` | Community | Yes | Mejorable | Reads merged feed; privacy-sensitive surface for minors. |
| ProfileScreen | `lib/features/profile/screens/profile_screen.dart` | `/profile` | Profile | Yes | Mejorable | Combines auth, chapters, sightings and badges state. |
| MySightingsScreen | `lib/features/sightings/screens/my_sightings_screen.dart` | `/sightings` | Sightings | Yes | Mejorable | Own sightings + archive/unarchive. |
| LocationSetupScreen | `lib/features/sightings/screens/location_setup_screen.dart` | `/sightings/location-setup` | Profile/sightings prerequisite | Yes | Mejorable | Route gate before first sighting if no country/city. |
| NicknameSetupScreen | `lib/features/auth/screens/nickname_setup_screen.dart` | `/nickname-setup` | Auth/profile completion | Yes | Mejorable | Route gate after login if nickname missing. |
| SettingsScreen | `lib/features/profile/screens/settings_screen.dart` | `/settings` | Settings | Yes | Mejorable | Real actions: theme, nickname, location, logout, delete account, privacy URL. Many expected settings are absent. |
| SightingFormScreen | `lib/features/sightings/screens/sighting_form_screen.dart` | `/sightings/new` | Sightings | Yes | Mejorable | GPS opt-in, photo upload, offline queue, edit/create modes. Critical release flow. |
| SightingFormScreen (edit mode) | `lib/features/sightings/screens/sighting_form_screen.dart` | `/sightings/:id/edit` | Sightings | Yes | Mejorable | Reuses create screen for updates. |

## Shell Navigation Inventory

| Branch | Root route | Screen | File |
| --- | --- | --- | --- |
| 0 | `/home` | HomeScreen | `lib/features/home/screens/home_screen.dart` |
| 1 | `/chapters` | ChaptersListScreen | `lib/features/education/screens/chapters_list_screen.dart` |
| 2 | `/game` | MapHubScreen | `lib/features/games/screens/map_hub_screen.dart` |
| 3 | `/map` | MapScreen | `lib/features/sightings/screens/map_screen.dart` |
| 4 | `/feed` | CommunityFeedScreen | `lib/features/sightings/screens/community_feed_screen.dart` |

## Non-Routed Product Surfaces

| Surface | File | Trigger |
| --- | --- | --- |
| SightingDetailsModal | `lib/features/home/widgets/sighting_details_modal.dart` | Home feed and map/community detail interactions |
| AvatarPickerSheet | `lib/features/profile/widgets/avatar_picker_sheet.dart` | Profile avatar edit |
| Delete account step 1 | `lib/features/profile/screens/settings_screen.dart` | Settings -> delete account |
| Delete account final confirm | `lib/features/profile/screens/settings_screen.dart` | Settings -> delete account |
| Nickname bottom sheet | `lib/features/profile/screens/settings_screen.dart` | Settings -> nickname |

## Route Guards Observed

Source: `redirect` in `lib/app.dart`

- Onboarding gate: any non-public route redirects to `/onboarding` until `LocalStorage.instance.onboardingDone == true`.
- Auth gate: any route outside allowlist redirects to `/login` while unauthenticated.
- Nickname gate: authenticated user hitting `/home` is redirected to `/nickname-setup` if nickname is missing and startup refresh is no longer pending.
- Location gate: authenticated user hitting `/sightings/new` is redirected to `/sightings/location-setup` if `country/city` are missing.

## Initial Screen-Level Risks

- `SplashScreen` uses a fixed wait and direct `LocalStorage` checks instead of awaiting auth refresh; risk of stale session routing and slow startup UX.
- `LoginScreen` exposes a visible forgot-password affordance, but no backend recovery flow exists yet.
- `SettingsScreen` includes only a subset of expected settings; many product-level controls requested in the audit prompt do not exist in code today.
- `ChapterDetailScreen` depends on remote/sample video URLs that are still placeholder content in schema and mock data.
- `MapScreen` and `CommunityFeedScreen` are privacy-sensitive surfaces because they expose user-generated content between accounts in a child-oriented product.
- `SightingFormScreen` is feature-rich and central to release readiness, but requires deeper pass on permission denial, background interruption, duplicate submission, offline sync and photo moderation behavior.

## Not Verified Yet

- Deep-link behavior on Android intents
- Back-stack behavior on physical Android back button for every route
- Exact empty/error/offline state quality for every screen
- Release-mode rendering and runtime-only issues
- Tablet and extreme-small-screen behavior
