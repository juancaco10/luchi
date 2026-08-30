# Google Play Child Location Review

Reviewed: 2026-08-25

## Current Safe Launch behavior

- `preciseLocationEnabled` is `false` in `lib/core/utils/constants.dart`.
- The client does not request GPS for new sightings in Safe Launch.
- Community routes are disabled in the client and `GET /sightings` is disabled
  by default in the backend.
- Country/city profile data can still be collected to place a private sighting
  approximately; this remains personal data and requires policy review.

## Risk and decision

Precise child location is not enabled for the initial production release.
Rounding to 100 m is not considered sufficient evidence of compliance.

## Legal review required

Before enabling precise location, counsel must approve the markets, parental
consent model, retention, disclosure, Data safety answers, and the exact
public/private geographic representation.

## Official sources consulted

- [Google Play Families Policies](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en), consulted 2026-08-25. The page notes a Families policy update effective 2026-08-26.
- [Google Play Data safety guidance](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en), consulted 2026-08-25.
