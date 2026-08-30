# Real Device Test Checklist

Status: required before release. Run against the newly signed AAB on Android.

- [x] Debug variant installed separately on SM-A346M; the Play Store app was
  preserved. This does not validate the signed release AAB.
- [x] Consent screen is reachable before onboarding completion and proceeds to
  login after the explicit checkbox is accepted.
- [x] Safe Launch login hides password recovery.
- [x] Guest entry reaches nickname selection; no fatal Android exception was
  observed. No guest account was created during this test.
- [ ] Install signed release AAB cleanly; verify package, version, and first
  launch.
- [ ] Complete onboarding and consent; confirm back navigation cannot bypass it.
- [ ] Register email account; confirm consent record appears in the database.
- [ ] Login/logout; verify account switching never displays prior-user profile,
  games, badges, chapters, or sightings.
- [ ] Test Google sign-in: cancel, success, repeat, logout, account change,
  existing email link, offline, invalid token.
- [ ] Create a sighting with no photo; owner sees it as pending/private.
- [ ] Upload own photo; submit it; reject an external URL, missing file, and
  another user's file through API integration tests.
- [ ] Confirm feed/map are inaccessible in Safe Launch.
- [ ] Confirm location permission is never requested in Safe Launch.
- [ ] Confirm no ad request or banner appears in Safe Launch.
- [ ] Play each game, complete a chapter, verify points/stars/badges after
  restart, offline operation, and account switch.
- [ ] Create sighting offline, kill/restart app, reconnect, and verify exactly
  one server record.
- [ ] Test account deletion including uploaded photo removal.
- [ ] Test 320x568, 360x640, 360x800, 393x873, 412x915 and tablet widths,
  keyboard behavior, Android back, text scale, and TalkBack.
