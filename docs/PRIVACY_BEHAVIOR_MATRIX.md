# Privacy Behavior Matrix

Reviewed from code: 2026-08-25. This is an engineering inventory, not legal advice.

| Data | Collected | Shared publicly in Safe Launch | Purpose | Required | Deletion path |
| --- | --- | --- | --- | --- | --- |
| Name and email | Yes, for password/Google accounts | No | Authentication and account | Password/Google account | `DELETE /me` |
| Google subject and token | Yes for Google sign-in | No | Account verification | Google sign-in only | `DELETE /me` removes account record |
| Avatar | Yes when selected/returned by Google | No, community disabled | Profile | Optional | `DELETE /me` |
| Sighting photo | Yes when user uploads | No, pending/private | Private sighting evidence | Optional | `DELETE /me`; upload ownership migration required |
| Country/city | Yes before a sighting | No, community disabled | Approximate private placement | Required for sightings | `DELETE /me` |
| Precise GPS | No in Safe Launch | No | Disabled | No | Not collected in Safe Launch |
| Notes | Yes, maximum 280 chars | No, pending/private | Private observation | Optional | `DELETE /me` |
| Progress and badges | Yes | No | Gamification | Required for feature | `DELETE /me` |
| Ad/advertising identifiers | Ads disabled in Safe Launch | Not applicable | Not applicable | No | Not applicable |

## Remaining review

- Server backup and retention behavior is not verified.
- Consent is stored locally with policy version and timestamp, but is not yet
  bound to an account or a legally approved verification method.
- Any change enabling ads, community, or precise GPS requires this matrix and
  store declarations to be reassessed.
