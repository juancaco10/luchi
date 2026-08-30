# Google Play Release Audit

Reviewed: 2026-08-25. Status: conditional, not submission-ready.

## Confirmed code posture

- Ads are disabled by Safe Launch. If enabled later, the implementation must
  configure child-directed treatment and maximum ad rating before SDK use.
- Community and public sightings are disabled in the client and backend by
  default.
- Precise GPS is disabled in the client.
- Account deletion exists in the API but needs deployed end-to-end validation.
- Release signing now fails closed without the user-managed release keystore.

## Play Console actions still required

- Provide accurate Target Audience and Content, IARC, Data safety, and privacy
  policy declarations.
- Verify the policy update effective 2026-08-26 before submission.
- Verify Google Sign-In OAuth clients and release certificate fingerprints.
- Complete a signed AAB build and device test.

## Official sources consulted

- [Families Policies](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en)
- [Data safety section guidance](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)
- [AdMob Families compliance](https://support.google.com/admob/answer/6223431?hl=en-GB)

All sources were consulted on 2026-08-25. The Families page identifies an
update effective 2026-08-26; it must be rechecked on the submission date.
