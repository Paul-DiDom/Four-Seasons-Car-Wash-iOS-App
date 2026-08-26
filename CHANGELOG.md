# Changelog

This file records notable source changes to the Four Seasons Car Wash iOS app.
Until version tags begin, repository milestones are identified by commit hash.
A commit, push, or successful build is not by itself evidence of an App Store
release.

Detailed status, validation matrices, server contracts, and rollout gates live
in the canonical [Car Wash Mobile Fleet Modernization and Store Release
Playbook](https://github.com/Paul-DiDom/RHCW-Android-App/blob/main/docs/PlayStore-API36-Playbook.md#ios-port-blueprint).

## [Unreleased] - 12.0 (build 1)

### Fixed

- **The saved UID now remains the authoritative app session until explicit Log Out or successful
  Delete Account.** Firebase's initial `nil` callback can race its asynchronous Keychain restore,
  especially during cold/background launch. That callback previously erased `loggedIn`, `userId`,
  and the saved email. Nil and stale/different-user callbacks are now identity-neutral and cannot
  hide, replace, or clear the saved account.
- The legacy `loggedIn` boolean is repaired from a valid saved UID instead of acting as a second
  login gate. A partially written or stale false flag therefore heals without asking the user to
  authenticate again.
- Authentication attempts cannot replace a different saved UID. Switching accounts requires the
  existing account to be explicitly logged out first.
- Sign-in no longer applies Registration's 6–16-character creation rule. Any nonempty password is
  sent to Firebase exactly as entered, allowing valid passwords created by the hosted reset page
  or by a suggested-password flow.
- Delete Account now treats its password as an existing credential too: any nonempty exact value
  reaches Firebase reauthentication, so a valid reset/suggested password longer than 16 characters
  no longer blocks the required in-app deletion path.

### Changed

- Prepared version `12.0`, build `1`, in both Debug and Release configurations.
- Updated the side-navigation version label from v11.0 to v12.0.
- Purchase, Gift Card, Transactions, Home, balances, and push-token association can use the saved
  UID immediately without waiting for Firebase authentication-state restoration.

### Security and behavior

- This release deliberately restores the app's historical session contract: the locally saved UID
  remains usable when Firebase is unavailable, signed out, revoked, or temporarily reports another
  user. Password changes and account deletion still require a matching live Firebase user and fail
  closed otherwise. Clearing app data or uninstalling the app remains outside this guarantee.

---

## [11.0] - build 1 (owner-reported released by 2026-08-26; exact date not recorded)

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
- Added a single-window `UIScene` lifecycle configuration. Cold-launch
  notification responses are routed through the same bounded, idempotent
  handler as notification-center callbacks.
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
- Prepared version `11.0`, build `1`, with an iOS 15 minimum,
  iPhone-only device family, Swift 5 target, standard plist dictionary version,
  and no obsolete `armv7` device capability.
- Re-encoded every App Store icon as visually identical opaque RGB PNG data so
  no icon contains an alpha channel.
- The resolved CocoaPods graph now uses direct FirebaseCore, FirebaseAuth, and
  FirebaseMessaging 12.17.0 products and no longer includes the unused
  SideMenu dependency.
- FCM global/location topic synchronization now waits until APNs registration
  and FCM token retrieval have both succeeded. Location changes update one
  queued desired state, and failed topic operations remain retryable.
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
- Fixed the Home layout conflict that pinned its content view to both the safe
  area bottom and the physical root-view bottom on home-indicator devices.
- Fixed the Home side-navigation conflict that assigned My Account a 265-point
  width while requiring both of its edges to match the 275-point Contact Us
  button. My Account now derives the shared width from those edge constraints.
- Fixed the Wash Code screen adding required 40-by-40 constraints to
  `UIStackView`-managed buttons on every appearance. The existing
  300-point `fillEqually` stack now owns their size without conflicts or
  accumulating duplicate constraints.
- Fixed launch-time FCM topic subscription requesting a registration token
  before the APNs device token existed.
- Replaced legacy app-window ownership with the UIKit scene lifecycle required
  by current platform guidance.
- Removed the redundant dynamic scene-configuration callback so UIKit uses the
  complete delegate/storyboard configuration in the app's scene manifest.
- Removed release-sensitive UID/token/email/password logging from the changed
  flows.
- Aligned every generated CocoaPods target with the app's iOS 15 minimum
  during `pod install`, removing unsupported iOS 9/11 deployment-target
  warnings from PromisesObjC, its privacy bundle, and RecaptchaInterop.
- Replaced the deprecated shared scroll-indicator inset API in Change Password
  with the vertical-axis API and converted two location-response diagnostic
  checks to nonbinding tests, addressing four current-Xcode source warnings
  without changing UI or network behavior.
- Fixed Home intermittently showing zero reward points after backing out of QR
  scanning. Balance refresh now waits for the verified account session, caches
  validated balance and points per account, rejects stale responses, and
  returns Login, Registration, Guest, and wash-error recovery flows to the
  existing Home controller.
- Fixed `/butp` responses containing grouped balances such as `$1,234.56` by
  parsing user type and points from the right and storing the canonical
  ungrouped `$1234.56` required by purchase screens. Saved-card lookup now runs
  independently of balance parsing and rejects out-of-order results.
- Bounded failed account refreshes to one automatic blocking attempt per
  refresh request, preserved PayPal intent, added request timeouts, and kept
  offline refreshes pending for the next Home appearance or app activation.
  Connectivity checks no longer depend on a stale process-global flag.
- Fixed Home account refresh becoming blocked when spinner presentation and
  dismissal overlapped or UIKit did not establish the spinner presentation.
  When Home presents its refresh spinner, balance work begins from that alert's
  presentation completion. The completion verifies exact alert ownership and
  re-dismisses one retired by cancellation; a next-main-turn attachment check
  preserves the refresh for a later attempt when no presentation relationship
  was created.
- Updated the side-navigation title from the stale `v10` text to `v11.0`,
  matching the release marketing version.

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
- That first run exposed one Home safe-area constraint conflict, launch-time
  FCM/APNs ordering warnings, and the UIKit scene-lifecycle warning. Source
  corrections are included after `2b25443`; a post-fix Mac/device run is
  still required before assigning runtime evidence to them.

### Release boundary

- The owner reports that `11.0 (1)` was released by 2026-08-26; the exact release
  date and individual archive/TestFlight/App Store evidence were not recorded.
- The clean Xcode builds, production APNs entitlement, device matrices, `/remove`
  checks, and store evidence listed here were open at the source-review milestone.
  They remain historical evidence gaps, not claims that 11.0 was unreleased.
- Current build/device/submission gates belong to the 12.0 hotfix above and to
  §§18.6–18.7 of the canonical playbook.
