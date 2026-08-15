# Changelog

This file records notable source changes to the Four Seasons Car Wash iOS app.
Until version tags begin, repository milestones are identified by commit hash.
A commit, push, or successful build is not by itself evidence of an App Store
release.

Detailed status, validation matrices, server contracts, and rollout gates live
in the canonical [Car Wash Mobile Fleet Modernization and Store Release
Playbook](https://github.com/Paul-DiDom/RHCW-Android-App/blob/main/docs/PlayStore-API36-Playbook.md#ios-port-blueprint).

## [Unreleased] - 10.1 (build 2)

### Added

- Added an app-lifetime account-session coordinator that reconciles the exact
  current Firebase user with the locally cached UID, owns authentication
  attempts, invalidates stale callbacks, signs Firebase out during logout, and
  synchronously stops private WebViews before targeted context cleanup.
- Added the Four Seasons `UID-HANDOFF-1` client for Purchase, Gift Card, and
  Transactions. It sends the current UID only in the HTTPS form body to the
  deployed canonical bootstrap and has no UID-bearing URL fallback.
- Added scoped password-visibility controls to Login, Registration, Change
  Password, and Delete Account. Registration uses one control for both new
  password fields; Change Password uses one control for current/new/confirm.
  Every form starts masked, preserves text/cursor selection, and exposes an
  accessible Show/Hide state with at least a 44-point target.
- Added an app-owned Change Password screen that reauthenticates the exact
  current Firebase user before updating the password and rejects stale-account
  callbacks or duplicate submissions.
- Added an APNs/FCM coordinator that waits for APNs readiness, associates the
  latest FCM token with the current account (or no account), de-duplicates only
  after backend success, and retries failures/account changes.
- Added lifecycle-safe FIFO notification-tap presentation from the active
  visible controller with normalized standard-content and Four Seasons
  `notice` fallback handling.
- Added an app-owned `PrivacyInfo.xcprivacy` declaring the
  `UserDefaults` required-reason API with reason `CA92.1`.
- Added a shared Xcode scheme for reproducible workspace builds.
- Added this changelog and linked the canonical fleet playbook.

### Changed

- Purchase, Gift Card, and Transactions now use the default persistent WebKit
  data store and the typed POST bootstrap. Generic Contact, Privacy,
  Promotions, and Rewards GET routes remain separate and unchanged.
- Logout and account deletion delete only `FS_UID_HANDOFF_1` for the exact
  Four Seasons host/path. Unrelated WebKit cookies and website data are not
  wiped.
- Private WebViews fail closed when the account changes, retain bootstrap
  errors until their view can present them, and do not automatically reload
  after WebKit process termination because payment outcome may be ambiguous.
- Saved-card lookup uses the deployed `/gcv2` wrapped response with exact
  four-field validation. Wash-purchase top-up uses
  `/impwvforwashv2` and accepts only its documented `Y`/`1`
  success values without a legacy retry/fallback.
- Account deletion now reauthenticates the already-current user, rechecks
  Firebase/local UID equality before token retrieval and response mutation,
  preserves the deployed `/remove` POST/wrapped-response contract, and
  waits for secure local cleanup before returning to Login.
- Notification response completion is always called; foreground presentation
  remains banner/list/sound, and background fetch now reports no data when the
  app performs no fetch work.
- Prepared version `10.1`, build `2`, with an iOS 15 minimum,
  iPhone-only device family, Swift 5 target, standard plist dictionary version,
  and no obsolete `armv7` device capability.
- Re-encoded every App Store icon as visually identical opaque RGB PNG data so
  no icon contains an alpha channel.
- The Podfile now uses direct FirebaseCore, FirebaseAuth, and
  FirebaseMessaging 12.17.0 products and removes the unused SideMenu
  dependency. The checked-in lockfile and Pods directory still represent the
  old Firebase 11.15/SideMenu graph until the required Mac CocoaPods step.
- Existing app-owned side navigation, its routes, and its presentation were
  intentionally retained; no Red Hill navigation redesign was copied.

### Fixed

- Fixed the prior local-only logout state, which could leave Firebase
  authenticated as a different account from the cached UID.
- Fixed overlapping Login/Registration callbacks that could commit stale
  authentication state or submit twice.
- Fixed the Registration progress-alert race and made follow-up UI wait for
  the owned alert to finish dismissing.
- Fixed Delete Account progress dismissal so errors and successful navigation
  are not presented during an in-progress UIKit dismissal.
- Fixed notification taps that could omit their completion handler, reject
  valid payload shapes, present from an inactive root controller, or lose the
  message behind a modal/transition.
- Fixed FCM refresh association that previously depended on a three-second
  Home timer, discarded refresh callbacks, and marked forwarding complete
  before the server confirmed success.
- Removed release-sensitive UID/token/email/password logging from the changed
  flows.

### Security and privacy

- New app source contains no UID query-string route. The UID remains an
  explicitly documented HTTPS POST-body disclosure protected afterward by the
  short-lived server context cookie; this is data minimization, not Firebase
  authentication.
- Every private handoff validates the current Firebase UID against the cached
  account immediately before building the POST. Logout/account switch blocks
  further private entry and invalidates open private WebViews.
- Passwords are never trimmed, logged, or persisted by the new auth UI and are
  cleared/remasked on teardown.
- No static app key is treated as authentication. Existing endpoint-specific
  compatibility keys remain only where required by deployed WCF contracts.

### Validation

- Windows static verification passed on 2026-08-15: `git diff --check`,
  plist/storyboard/privacy/entitlement/workspace/scheme XML parsing, Xcode
  source/resource membership, WebView/UID URL scans, dependency/import review,
  and AppIcon dimensions/color-type inspection.
- Independent source review found no remaining Swift, UIKit/Firebase API,
  session-race, UID-handoff, or WCF contract blocker.
- All password fields that host an eye control resolve to 48 or 50 points in
  the storyboard/programmatic layout.
- CocoaPods follow-up `f74e9aa` is committed/pushed: `Podfile.lock` and
  `Pods/Manifest.lock` are byte-identical, resolve FirebaseAuth,
  FirebaseCore, and FirebaseMessaging 12.17.0 under CocoaPods 1.15.2, and no
  longer contain Firebase Analytics, Google App Measurement, or SideMenu.
- `BUILD/RUN GREEN - OWNER-REPORTED 2026-08-15` after running
  `pod install --repo-update` and committing/pushing `f74e9aa`: the
  app builds and runs fine. Exact Xcode version, build configuration,
  simulator/device, and iOS version were not recorded, so this closes the
  dependency-resolution/first-build gate only. It is not Release archive,
  TestFlight, or focused feature/device evidence.

### Release gates

- CocoaPods resolution is complete at `f74e9aa`. Continue to build the
  tracked `Four Seasons Car Wash.xcworkspace`; do not use the
  `.xcodeproj` or reintroduce the removed aggregate/SideMenu pods.
- Clean-build Debug and Release with Xcode 26.2 or newer, then create and
  validate a signed archive. Confirm the distribution product resolves
  `aps-environment` to `production`.
- Confirm `10.1 (2)` has never been uploaded in App Store Connect before
  archiving; increment the build if it has.
- Complete the playbook device matrices for UID POST/303/cookie continuity,
  payment/provider return, logout/account switch/process death, Login/Register,
  password eyes/Change Password/Delete Account, push permission/token/topic/tap
  lifecycle, existing side navigation, Dynamic Type, and VoiceOver.
- Run disposable same-user-success and cross-user-fail-closed `/remove`
  checks, internal TestFlight with production APNs, privacy-report/label review,
  archive validation, and App Store submission before moving this section to a
  dated release.
