import FirebaseMessaging
import Foundation
import UIKit

/// Associates the current FCM token with the exact current account (or no
/// account) only after APNs registration. Successful token/account pairs are
/// de-duplicated; failed requests remain retryable.
final class PushTokenCoordinator {
    static let shared = PushTokenCoordinator()
    private static let locationTopics = [
        "perth",
        "cornwall",
        "arnprior",
        "carleton"
    ]

    private struct Association: Hashable {
        let token: String
        let userID: String
    }

    private struct TopicState: Equatable {
        let token: String
        let site: Int
    }

    private var apnsIsReady = false
    private var latestFCMToken: String?
    private var inFlightAssociation: Association?
    private var lastSuccessfulAssociation: Association?
    private var retryWorkItem: DispatchWorkItem?
    private var desiredSite: Int
    private var lastSuccessfulTopicState: TopicState?
    private var topicSyncInFlight = false
    private var topicSyncGeneration = 0
    private var topicOperationsRemaining = 0
    private var topicOperationFailed = false
    private var topicStateBeingSynchronized: TopicState?
    private var topicRetryWorkItem: DispatchWorkItem?

    private init() {
        desiredSite = Self.normalizedSite(
            UserDefaults.standard.integer(forKey: "site")
        )
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
            self.synchronizeTopicsIfPossible()
            self.attemptAssociation()
            self.requestCurrentFCMToken()
        }
    }

    func didReceiveFCMToken(_ token: String) {
        runOnMain {
            let normalizedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
            guard normalizedToken.count > 5 else { return }
            self.latestFCMToken = normalizedToken
            self.synchronizeTopicsIfPossible()
            self.attemptAssociation()
        }
    }

    func selectedSiteDidChange(to site: Int) {
        runOnMain {
            self.desiredSite = Self.normalizedSite(site)
            self.synchronizeTopicsIfPossible()
        }
    }

    func accountDidChange() {
        runOnMain {
            self.attemptAssociation()
        }
    }

    @objc private func applicationDidBecomeActive() {
        if apnsIsReady && latestFCMToken == nil {
            requestCurrentFCMToken()
        }
        synchronizeTopicsIfPossible()
        attemptAssociation()
    }

    private func requestCurrentFCMToken() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard apnsIsReady else { return }
        Messaging.messaging().token { [weak self] token, _ in
            guard let self = self,
                  let token = token else {
                return
            }
            self.didReceiveFCMToken(token)
        }
    }

    private func synchronizeTopicsIfPossible() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard apnsIsReady,
              let token = latestFCMToken,
              token.count > 5,
              !topicSyncInFlight,
              lastSuccessfulTopicState != TopicState(
                  token: token,
                  site: desiredSite
              ) else {
            return
        }

        topicRetryWorkItem?.cancel()
        topicRetryWorkItem = nil

        let topicState = TopicState(token: token, site: desiredSite)
        let selectedTopic = Self.locationTopic(for: topicState.site)
        let operations = [("all", true)] + Self.locationTopics.map {
            ($0, $0 == selectedTopic)
        }

        topicSyncGeneration += 1
        let generation = topicSyncGeneration
        topicSyncInFlight = true
        topicOperationsRemaining = operations.count
        topicOperationFailed = false
        topicStateBeingSynchronized = topicState

        for (topic, shouldSubscribe) in operations {
            let completion: (Error?) -> Void = { [weak self] error in
                self?.runOnMain { [weak self] in
                    self?.finishTopicOperation(
                        generation: generation,
                        error: error
                    )
                }
            }
            if shouldSubscribe {
                Messaging.messaging().subscribe(
                    toTopic: topic,
                    completion: completion
                )
            }
            else {
                Messaging.messaging().unsubscribe(
                    fromTopic: topic,
                    completion: completion
                )
            }
        }
    }

    private func finishTopicOperation(generation: Int, error: Error?) {
        dispatchPrecondition(condition: .onQueue(.main))
        guard topicSyncInFlight,
              generation == topicSyncGeneration else {
            return
        }

        if error != nil {
            topicOperationFailed = true
        }
        topicOperationsRemaining -= 1
        guard topicOperationsRemaining == 0 else { return }

        let synchronizedState = topicStateBeingSynchronized
        let failed = topicOperationFailed
        topicSyncInFlight = false
        topicStateBeingSynchronized = nil
        let currentState = currentDesiredTopicState()
        if !failed,
           synchronizedState == currentState {
            lastSuccessfulTopicState = synchronizedState
        }

        if synchronizedState != currentState {
            synchronizeTopicsIfPossible()
        }
        else if failed {
            scheduleTopicRetry()
        }
    }

    private func scheduleTopicRetry() {
        guard topicRetryWorkItem == nil else { return }
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.topicRetryWorkItem = nil
            self.synchronizeTopicsIfPossible()
        }
        topicRetryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0, execute: workItem)
    }

    private static func normalizedSite(_ site: Int) -> Int {
        return (1...locationTopics.count).contains(site) ? site : 0
    }

    private static func locationTopic(for site: Int) -> String? {
        guard (1...locationTopics.count).contains(site) else {
            return nil
        }
        return locationTopics[site - 1]
    }

    private func currentDesiredTopicState() -> TopicState? {
        guard apnsIsReady,
              let token = latestFCMToken,
              token.count > 5 else {
            return nil
        }
        return TopicState(token: token, site: desiredSite)
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
