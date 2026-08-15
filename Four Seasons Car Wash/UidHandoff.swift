import Foundation
import WebKit

/// Four Seasons client for the additive UID-HANDOFF-1 hosted-page bootstrap.
///
/// The Firebase UID is sent only in an HTTPS form body. It must never be
/// logged, persisted as WebView state, or restored through a legacy URL.
enum UidHandoff {
    enum Destination: String {
        case purchase
        case gift
        case transactions

        fileprivate var minimumUserIdLength: Int {
            switch self {
            case .purchase, .gift:
                return 10
            case .transactions:
                return 8
            }
        }
    }

    enum HandoffError: LocalizedError {
        case authenticationLoading
        case accountUnavailable
        case invalidRequest

        var errorDescription: String? {
            switch self {
            case .authenticationLoading:
                return "Your account is still loading. Please try again."
            case .accountUnavailable:
                return "Your account could not be connected securely. Please log out, log in, and try again."
            case .invalidRequest:
                return "The secure account page could not be opened. Please try again."
            }
        }
    }

    private static let endpoint = URL(
        string: "https://www.tech1app.com/fourseasons/mobile-entry.aspx"
    )!
    private static let contract = "UID-HANDOFF-1"
    private static let cookieName = "FS_UID_HANDOFF_1"
    private static let cookieHost = "www.tech1app.com"
    private static let cookiePath = "/fourseasons/"
    private static let maximumBodyLength = 1024
    private static let maximumUserIdLength = 128
    /// Builds the POST immediately before WebKit sends it, using the current
    /// authenticated account rather than a controller-cached UID.
    static func currentRequest(
        for destination: Destination,
        session: AccountSession.Snapshot
    ) throws -> URLRequest {
        guard AccountSession.isAuthenticationStateResolved else {
            throw HandoffError.authenticationLoading
        }
        guard AccountSession.isCurrent(session),
              isValidUserId(session.userID, for: destination) else {
            throw HandoffError.accountUnavailable
        }

        let fields = [
            ("contract", contract),
            ("destination", destination.rawValue),
            ("userID", session.userID)
        ]
        let form = fields
            .map { formEncode($0.0) + "=" + formEncode($0.1) }
            .joined(separator: "&")
        guard let body = form.data(using: .utf8),
              !body.isEmpty,
              body.count <= maximumBodyLength else {
            throw HandoffError.invalidRequest
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.httpBody = body
        request.httpShouldHandleCookies = true
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue(
            "application/x-www-form-urlencoded; charset=utf-8",
            forHTTPHeaderField: "Content-Type"
        )
        return request
    }

    /// Compatibility accessor for account UI that still needs the exact
    /// resolved user. Private WebViews should retain a typed session snapshot.
    static func currentAuthenticatedUserId() -> String? {
        return AccountSession.currentSnapshot()?.userID
    }

    /// Deletes only the Four Seasons private-handoff context. Other website
    /// cookies and website data are deliberately left untouched.
    static func deleteContextCookie(completion: @escaping (Bool) -> Void) {
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        cookieStore.getAllCookies { cookies in
            let matchingCookies = cookies.filter(isContextCookie)
            guard !matchingCookies.isEmpty else {
                DispatchQueue.main.async {
                    completion(true)
                }
                return
            }

            let deletionGroup = DispatchGroup()
            for cookie in matchingCookies {
                deletionGroup.enter()
                cookieStore.delete(cookie) {
                    deletionGroup.leave()
                }
            }
            deletionGroup.notify(queue: .main) {
                cookieStore.getAllCookies { remainingCookies in
                    let wasDeleted = !remainingCookies.contains(where: isContextCookie)
                    DispatchQueue.main.async {
                        completion(wasDeleted)
                    }
                }
            }
        }
    }

    static func isValidSessionUserID(_ userID: String) -> Bool {
        return isValidUserId(userID, for: .transactions)
    }

    private static func isValidUserId(
        _ userId: String,
        for destination: Destination
    ) -> Bool {
        guard userId.count >= destination.minimumUserIdLength,
              userId.count <= maximumUserIdLength else {
            return false
        }

        return userId.utf8.allSatisfy { byte in
            (byte >= 48 && byte <= 57) ||
                (byte >= 65 && byte <= 90) ||
                (byte >= 97 && byte <= 122) ||
                byte == 45 ||
                byte == 95
        }
    }

    private static func formEncode(_ value: String) -> String {
        return value.utf8.map { byte in
            switch byte {
            case 48...57, 65...90, 97...122, 45, 46, 95, 42:
                return String(UnicodeScalar(byte))
            case 32:
                return "+"
            default:
                return String(format: "%%%02X", byte)
            }
        }.joined()
    }

    private static func isContextCookie(_ cookie: HTTPCookie) -> Bool {
        let normalizedDomain = cookie.domain
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            .lowercased()
        return cookie.name == cookieName &&
            normalizedDomain == cookieHost &&
            cookie.path == cookiePath
    }
}
