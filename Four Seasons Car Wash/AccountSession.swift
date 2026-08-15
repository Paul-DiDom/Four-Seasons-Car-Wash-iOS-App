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

/// Owns the one Firebase/local account session for the lifetime of the app.
///
/// Private hosted pages must use a `Snapshot` immediately before loading. A
/// snapshot becomes invalid on logout, account switch, or any Firebase/local
/// identity mismatch.
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
              UidHandoff.isValidSessionUserID(user.uid) else {
            cancelAuthenticationAttempt(attemptID)
            return false
        }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "loggedIn")
        defaults.set(user.uid, forKey: "userId")
        defaults.set(normalizedEmail, forKey: "userEmail")
        defaults.set(normalizedEmail, forKey: "email")
        defaults.set(true, forKey: "checkBalance")

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
        guard isAuthenticationStateResolved,
              !isContextCleanupInProgress,
              !contextCleanupFailed,
              activeAuthenticationAttemptID == nil else {
            return nil
        }

        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: "loggedIn"),
              let cachedUserID = defaults.string(forKey: "userId"),
              let firebaseUser = Auth.auth().currentUser,
              firebaseUser.uid == cachedUserID,
              UidHandoff.isValidSessionUserID(firebaseUser.uid) else {
            return nil
        }

        let accountEmail = firebaseUser.email ??
            defaults.string(forKey: "userEmail") ?? ""
        return Snapshot(
            userID: firebaseUser.uid,
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
        explicitlyInvalidateSession()

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

        if defaults.bool(forKey: "loggedIn"),
           let cachedUserID = defaults.string(forKey: "userId"),
           let firebaseUser = firebaseUser,
           firebaseUser.uid == cachedUserID,
           UidHandoff.isValidSessionUserID(firebaseUser.uid) {
            let accountEmail = firebaseUser.email ??
                defaults.string(forKey: "userEmail") ?? ""
            applyLegacyGlobals(userID: firebaseUser.uid, email: accountEmail)
            contextCleanupFailed = false
            NotificationCenter.default.post(name: .accountSessionDidChange, object: nil)
            PushTokenCoordinator.shared.accountDidChange()
            return
        }

        explicitlyInvalidateSession()
        if firebaseUser != nil {
            try? Auth.auth().signOut()
        }
        clearPrivateContext { _ in
            explicitInvalidationInProgress = false
            PushTokenCoordinator.shared.accountDidChange()
        }
    }

    private static func explicitlyInvalidateSession() {
        dispatchPrecondition(condition: .onQueue(.main))
        explicitInvalidationInProgress = true
        activeAuthenticationAttemptID = nil
        sessionGeneration &+= 1

        let defaults = UserDefaults.standard
        defaults.set(false, forKey: "loggedIn")
        defaults.removeObject(forKey: "userId")
        defaults.removeObject(forKey: "userEmail")
        defaults.removeObject(forKey: "email")
        defaults.set(false, forKey: "paypal")
        defaults.set(false, forKey: "coinAdd")
        defaults.set("$0.00", forKey: "balance")
        defaults.set(false, forKey: "checkBalance")

        applyLegacyGlobals(userID: "", email: "")
        savedCard = ""
        hasSavedCard = false
        userType = regularUser
        points = "0"
        checkBalance = false

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
}
