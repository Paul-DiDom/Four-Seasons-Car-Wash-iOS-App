import FirebaseAuth
import Foundation

extension Notification.Name {
    static let accountSessionDidChange = Notification.Name(
        "FourSeasons.accountSessionDidChange"
    )
    static let accountSessionDidInvalidate = Notification.Name(
        "FourSeasons.accountSessionDidInvalidate"
    )
    static let accountSessionAvailabilityDidChange = Notification.Name(
        "FourSeasons.accountSessionAvailabilityDidChange"
    )
}

enum AccountBalanceStore {
    struct Values {
        let balance: String
        let rewardPoints: String
    }

    static let balanceKey = "balance"
    static let rewardPointsKey = "rewardPoints"
    static let ownerKey = "accountBalanceOwner"
    static let refreshRequiredKey = "checkBalance"
    // Keep failed data marked stale without reopening a blocking alert on
    // every Home appearance. A new refresh request clears this suppression.
    private(set) static var automaticRetrySuppressed = false
    private(set) static var retryPromptPending = false

    static func cachedValues(
        for userID: String,
        defaults: UserDefaults = .standard
    ) -> Values? {
        guard defaults.string(forKey: ownerKey) == userID,
              let storedBalance = defaults.string(forKey: balanceKey),
              storedBalance.starts(with: "$"),
              let storedAmount = Double(String(storedBalance.dropFirst())),
              storedAmount.isFinite,
              let storedPoints = defaults.string(forKey: rewardPointsKey),
              let numericPoints = Int(storedPoints),
              numericPoints >= 0 else {
            return nil
        }
        return Values(
            balance: storedBalance,
            rewardPoints: String(numericPoints)
        )
    }

    static func store(
        balance: String,
        rewardPoints: String,
        for userID: String,
        defaults: UserDefaults = .standard
    ) {
        defaults.removeObject(forKey: ownerKey)
        defaults.set(balance, forKey: balanceKey)
        defaults.set(rewardPoints, forKey: rewardPointsKey)
        defaults.set(userID, forKey: ownerKey)
    }

    static func markRefreshRequired(defaults: UserDefaults = .standard) {
        automaticRetrySuppressed = false
        retryPromptPending = false
        defaults.set(true, forKey: refreshRequiredKey)
    }

    static func preserveFailedRefresh(defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: refreshRequiredKey) else { return }
        defaults.set(true, forKey: refreshRequiredKey)
        automaticRetrySuppressed = true
        retryPromptPending = true
    }

    static func consumeRetryPrompt() {
        retryPromptPending = false
    }

    static func clear(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: ownerKey)
        defaults.set("$0.00", forKey: balanceKey)
        defaults.removeObject(forKey: rewardPointsKey)
        defaults.set(false, forKey: refreshRequiredKey)
        automaticRetrySuppressed = false
        retryPromptPending = false
    }
}

/// Owns the one Firebase/local account session for the lifetime of the app.
///
/// Private hosted pages must use a `Snapshot` immediately before loading. A
/// snapshot becomes invalid only when the app-owned saved account changes,
/// including explicit logout or successful account deletion.
enum AccountSession {
    struct Snapshot: Equatable {
        let userID: String
        let email: String
        fileprivate let generation: UInt64
    }

    private static var authStateHandle: AuthStateDidChangeListenerHandle?
    private static var activeAuthenticationAttemptID: UUID?
    private static var cookieCleanupCompletions: [(Bool) -> Void] = []
    private static var sessionGeneration: UInt64 = 0
    private static var started = false
    private static var explicitInvalidationInProgress = false

    private(set) static var isAuthenticationStateResolved = false
    private(set) static var isContextCleanupInProgress = false
    private(set) static var contextCleanupFailed = false

    static var canBeginAuthentication: Bool {
        return isAuthenticationStateResolved &&
            !isContextCleanupInProgress &&
            !contextCleanupFailed &&
            persistedSessionUserID() == nil &&
            activeAuthenticationAttemptID == nil
    }

    static var authenticationUnavailableMessage: String {
        if contextCleanupFailed {
            return "The previous secure session could not be cleared. Please restart the app and try again."
        }
        return "Your account is still loading. Please try again."
    }

    static func start() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard !started else { return }
        started = true

        authStateHandle = Auth.auth().addStateDidChangeListener { _, firebaseUser in
            DispatchQueue.main.async {
                isAuthenticationStateResolved = true
                NotificationCenter.default.post(
                    name: .accountSessionAvailabilityDidChange,
                    object: nil
                )

                // Firebase may publish the new user before the sign-in
                // completion. The completion owns committing that exact attempt.
                guard activeAuthenticationAttemptID == nil,
                      !explicitInvalidationInProgress else {
                    return
                }
                reconcile(firebaseUser: firebaseUser)
            }
        }
    }

    static func beginAuthenticationAttempt() -> UUID? {
        dispatchPrecondition(condition: .onQueue(.main))
        guard canBeginAuthentication else { return nil }
        let attemptID = UUID()
        activeAuthenticationAttemptID = attemptID
        return attemptID
    }

    static func isCurrentAuthenticationAttempt(_ attemptID: UUID) -> Bool {
        dispatchPrecondition(condition: .onQueue(.main))
        return activeAuthenticationAttemptID == attemptID
    }

    @discardableResult
    static func completeAuthenticationAttempt(
        _ attemptID: UUID,
        user: User,
        email: String
    ) -> Bool {
        dispatchPrecondition(condition: .onQueue(.main))
        guard activeAuthenticationAttemptID == attemptID,
              Auth.auth().currentUser?.uid == user.uid,
              UidHandoff.isValidSessionUserID(user.uid),
              persistedSessionUserID().map({ $0 == user.uid }) ?? true else {
            cancelAuthenticationAttempt(attemptID)
            return false
        }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let defaults = UserDefaults.standard
        defaults.set(user.uid, forKey: "userId")
        defaults.set(true, forKey: "loggedIn")
        defaults.set(normalizedEmail, forKey: "userEmail")
        defaults.set(normalizedEmail, forKey: "email")
        AccountBalanceStore.markRefreshRequired(defaults: defaults)

        sessionGeneration &+= 1
        activeAuthenticationAttemptID = nil
        applyLegacyGlobals(userID: user.uid, email: normalizedEmail)
        contextCleanupFailed = false

        NotificationCenter.default.post(name: .accountSessionDidChange, object: nil)
        NotificationCenter.default.post(
            name: .accountSessionAvailabilityDidChange,
            object: nil
        )
        PushTokenCoordinator.shared.accountDidChange()
        return true
    }

    static func cancelAuthenticationAttempt(_ attemptID: UUID) {
        dispatchPrecondition(condition: .onQueue(.main))
        guard activeAuthenticationAttemptID == attemptID else { return }
        activeAuthenticationAttemptID = nil
        NotificationCenter.default.post(
            name: .accountSessionAvailabilityDidChange,
            object: nil
        )

        if isAuthenticationStateResolved && !explicitInvalidationInProgress {
            reconcile(firebaseUser: Auth.auth().currentUser)
        }
    }

    static func currentSnapshot() -> Snapshot? {
        dispatchPrecondition(condition: .onQueue(.main))
        guard !isContextCleanupInProgress,
              !contextCleanupFailed,
              activeAuthenticationAttemptID == nil else {
            return nil
        }

        // THE APP OWNS THE SESSION, NOT FIREBASE.
        //
        // Firebase verifies the password once at sign-in;
        // `completeAuthenticationAttempt` records the UID it returned, and that
        // record stands until an explicit logout or account deletion clears it.
        // That is the pre-11.0 behaviour, and it is what the Android client and
        // the WCF backend have always relied on.
        let defaults = UserDefaults.standard
        guard let cachedUserID = persistedSessionUserID(defaults: defaults) else {
            return nil
        }

        // Keep the legacy flag synchronized, but never use it as a second gate.
        // A partial old write with a valid UID must heal to logged in.
        if !defaults.bool(forKey: "loggedIn") {
            defaults.set(true, forKey: "loggedIn")
        }

        // Firebase can enrich the matching saved account with its email, but a
        // nil or different live Firebase user cannot replace, hide, or clear it.
        let firebaseUser = Auth.auth().currentUser
        let firebaseEmail = firebaseUser?.uid == cachedUserID
            ? firebaseUser?.email
            : nil
        let accountEmail = firebaseEmail ??
            defaults.string(forKey: "userEmail") ?? ""
        return Snapshot(
            userID: cachedUserID,
            email: accountEmail,
            generation: sessionGeneration
        )
    }

    static func isCurrent(_ snapshot: Snapshot) -> Bool {
        dispatchPrecondition(condition: .onQueue(.main))
        guard let current = currentSnapshot() else { return false }
        return current.userID == snapshot.userID &&
            current.generation == snapshot.generation
    }

    static func logOut(completion: @escaping (Bool) -> Void) {
        dispatchPrecondition(condition: .onQueue(.main))
        clearPersistedSessionForExplicitLogout()

        do {
            try Auth.auth().signOut()
        }
        catch {
            // Local invalidation and targeted WebKit cleanup remain mandatory
            // even when Firebase has already discarded the account locally.
        }

        clearPrivateContext { success in
            explicitInvalidationInProgress = false
            PushTokenCoordinator.shared.accountDidChange()
            completion(success)
        }
    }

    static func completeAccountDeletion(completion: @escaping (Bool) -> Void) {
        logOut(completion: completion)
    }

    static func retryContextCleanup(completion: @escaping (Bool) -> Void) {
        dispatchPrecondition(condition: .onQueue(.main))
        clearPrivateContext(completion: completion)
    }

    private static func reconcile(firebaseUser: User?) {
        dispatchPrecondition(condition: .onQueue(.main))
        let defaults = UserDefaults.standard

        guard let cachedUserID = persistedSessionUserID(defaults: defaults) else {
            // Firebase callbacks are identity-neutral. Without an app-owned
            // saved UID there is no app session to create, replace, or clear.
            applyLegacyGlobals(userID: "", email: "")
            return
        }

        defaults.set(true, forKey: "loggedIn")
        let firebaseEmail = firebaseUser?.uid == cachedUserID
            ? firebaseUser?.email
            : nil
        let accountEmail = firebaseEmail ??
            defaults.string(forKey: "userEmail") ?? ""
        applyLegacyGlobals(userID: cachedUserID, email: accountEmail)
        contextCleanupFailed = false
        NotificationCenter.default.post(name: .accountSessionDidChange, object: nil)
        PushTokenCoordinator.shared.accountDidChange()
    }

    private static func clearPersistedSessionForExplicitLogout() {
        dispatchPrecondition(condition: .onQueue(.main))
        explicitInvalidationInProgress = true
        activeAuthenticationAttemptID = nil
        sessionGeneration &+= 1

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "userId")
        defaults.set(false, forKey: "loggedIn")
        defaults.removeObject(forKey: "userEmail")
        defaults.removeObject(forKey: "email")
        defaults.set(false, forKey: "paypal")
        defaults.set(false, forKey: "coinAdd")
        AccountBalanceStore.clear(defaults: defaults)

        applyLegacyGlobals(userID: "", email: "")
        savedCard = ""
        hasSavedCard = false

        // Synchronous delivery lets every open private WebView stop before
        // the cookie is removed or a newer account can authenticate.
        NotificationCenter.default.post(name: .accountSessionDidInvalidate, object: nil)
        NotificationCenter.default.post(name: .accountSessionDidChange, object: nil)
        NotificationCenter.default.post(
            name: .accountSessionAvailabilityDidChange,
            object: nil
        )
    }

    private static func clearPrivateContext(completion: @escaping (Bool) -> Void) {
        dispatchPrecondition(condition: .onQueue(.main))
        cookieCleanupCompletions.append(completion)
        guard !isContextCleanupInProgress else { return }

        isContextCleanupInProgress = true
        contextCleanupFailed = false
        NotificationCenter.default.post(
            name: .accountSessionAvailabilityDidChange,
            object: nil
        )

        UidHandoff.deleteContextCookie { success in
            isContextCleanupInProgress = false
            contextCleanupFailed = !success
            let completions = cookieCleanupCompletions
            cookieCleanupCompletions.removeAll()

            NotificationCenter.default.post(
                name: .accountSessionAvailabilityDidChange,
                object: nil
            )
            completions.forEach { $0(success) }
        }
    }

    private static func applyLegacyGlobals(userID: String, email: String) {
        userId = userID
        userEmail = email
        isLoggedIn = !userID.isEmpty
    }

    private static func persistedSessionUserID(
        defaults: UserDefaults = .standard
    ) -> String? {
        guard let savedUserID = defaults.string(forKey: "userId"),
              UidHandoff.isValidSessionUserID(savedUserID) else {
            return nil
        }
        return savedUserID
    }
}
