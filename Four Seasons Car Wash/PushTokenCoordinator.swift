import FirebaseMessaging
import Foundation
import UIKit

/// Associates the current FCM token with the exact current account (or no
/// account) only after APNs registration. Successful token/account pairs are
/// de-duplicated; failed requests remain retryable.
final class PushTokenCoordinator {
    static let shared = PushTokenCoordinator()

    private struct Association: Hashable {
        let token: String
        let userID: String
    }

    private var apnsIsReady = false
    private var latestFCMToken: String?
    private var inFlightAssociation: Association?
    private var lastSuccessfulAssociation: Association?
    private var retryWorkItem: DispatchWorkItem?

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    func apnsDidRegister() {
        runOnMain {
            self.apnsIsReady = true
            Messaging.messaging().token { token, _ in
                guard let token = token else { return }
                self.didReceiveFCMToken(token)
            }
        }
    }

    func didReceiveFCMToken(_ token: String) {
        runOnMain {
            let normalizedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
            guard normalizedToken.count > 5 else { return }
            self.latestFCMToken = normalizedToken
            self.attemptAssociation()
        }
    }

    func accountDidChange() {
        runOnMain {
            self.attemptAssociation()
        }
    }

    @objc private func applicationDidBecomeActive() {
        attemptAssociation()
    }

    private func attemptAssociation() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard apnsIsReady,
              let token = latestFCMToken,
              token.count > 5 else {
            return
        }

        let currentUserID = AccountSession.currentSnapshot()?.userID ?? ""
        let association = Association(token: token, userID: currentUserID)
        guard inFlightAssociation == nil,
              lastSuccessfulAssociation != association else {
            return
        }

        guard let url = URL(string: service + "t"),
              let body = try? JSONSerialization.data(withJSONObject: [
                  "i": association.userID,
                  "t": association.token,
                  "k": "2Pr6Tg3XlPq"
              ]) else {
            return
        }

        retryWorkItem?.cancel()
        retryWorkItem = nil
        inFlightAssociation = association

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "application/json; charset=utf-8",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = body
        request.timeoutInterval = 20.0

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            let success: Bool
            if error == nil,
               let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                success = json["tResult"] as? String == "1"
            }
            else {
                success = false
            }

            DispatchQueue.main.async {
                guard let self = self,
                      self.inFlightAssociation == association else {
                    return
                }
                self.inFlightAssociation = nil

                let desiredUserID = AccountSession.currentSnapshot()?.userID ?? ""
                let desiredAssociation = Association(
                    token: self.latestFCMToken ?? "",
                    userID: desiredUserID
                )
                if success && desiredAssociation == association {
                    self.lastSuccessfulAssociation = association
                    return
                }
                if desiredAssociation != association {
                    self.attemptAssociation()
                }
                else {
                    self.scheduleRetry()
                }
            }
        }.resume()
    }

    private func scheduleRetry() {
        guard retryWorkItem == nil else { return }
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.retryWorkItem = nil
            self.attemptAssociation()
        }
        retryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0, execute: workItem)
    }

    private func runOnMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        }
        else {
            DispatchQueue.main.async(execute: work)
        }
    }
}
