import UIKit
import UserNotifications

/// Queues notification taps until an active scene has a visible presenter.
/// Messages are removed only after UIKit confirms presentation.
final class NotificationTapPresenter {
    static let shared = NotificationTapPresenter()

    private struct PendingMessage {
        let id = UUID()
        let title: String
        let body: String
    }

    private var pendingMessages: [PendingMessage] = []
    private var isPresenting = false
    private weak var currentAlert: UIAlertController?
    private var retryScheduled = false
    private var retryCount = 0
    private var handledResponseKeys = Set<String>()
    private var handledResponseOrder: [String] = []

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    func enqueue(title: String, body: String) {
        let work = {
            self.pendingMessages.append(PendingMessage(title: title, body: body))
            self.retryCount = 0
            self.presentNextIfPossible()
        }
        if Thread.isMainThread {
            work()
        }
        else {
            DispatchQueue.main.async(execute: work)
        }
    }

    /// Handles both notification-center callbacks and notification responses
    /// delivered while UIKit creates a new scene. A bounded response-key cache
    /// prevents the same tap from being shown twice if both paths report it.
    func handle(response: UNNotificationResponse) {
        let work = {
            guard response.actionIdentifier ==
                    UNNotificationDefaultActionIdentifier else {
                return
            }

            let request = response.notification.request
            let responseKey = [
                response.actionIdentifier,
                request.identifier,
                String(response.notification.date.timeIntervalSinceReferenceDate)
            ].joined(separator: "|")
            guard self.handledResponseKeys.insert(responseKey).inserted else {
                return
            }
            self.handledResponseOrder.append(responseKey)
            if self.handledResponseOrder.count > 64 {
                let expiredKey = self.handledResponseOrder.removeFirst()
                self.handledResponseKeys.remove(expiredKey)
            }

            let content = request.content
            let normalizedBody = content.body
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let fallbackBody = (content.userInfo["notice"] as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let body = normalizedBody.isEmpty ? fallbackBody : normalizedBody
            guard !body.isEmpty else { return }

            let normalizedTitle = content.title
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let title = normalizedTitle.isEmpty
                ? "Four Seasons Car Wash"
                : normalizedTitle
            self.pendingMessages.append(
                PendingMessage(title: title, body: body)
            )
            self.retryCount = 0
            self.presentNextIfPossible()
        }
        if Thread.isMainThread {
            work()
        }
        else {
            DispatchQueue.main.async(execute: work)
        }
    }

    @objc private func applicationDidBecomeActive() {
        retryCount = 0
        presentNextIfPossible()
    }

    private func presentNextIfPossible() {
        dispatchPrecondition(condition: .onQueue(.main))

        // UIKit can dismiss an alert while the app changes controller stacks.
        // Recover the queue instead of leaving it permanently marked as presenting.
        if isPresenting,
           currentAlert?.presentingViewController == nil {
            isPresenting = false
            self.currentAlert = nil
        }

        guard !isPresenting,
              !pendingMessages.isEmpty,
              UIApplication.shared.applicationState == .active,
              let presenter = activePresenter(),
              presenter.viewIfLoaded?.window != nil,
              !presenter.isBeingDismissed,
              !presenter.isBeingPresented,
              presenter.transitionCoordinator == nil else {
            scheduleRetryIfUseful()
            return
        }

        if presenter is UIAlertController {
            scheduleRetryIfUseful()
            return
        }

        let message = pendingMessages[0]
        let alert = UIAlertController(
            title: message.title,
            message: message.body,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.isPresenting = false
            self.currentAlert = nil
            self.retryCount = 0
            self.presentNextIfPossible()
        })

        isPresenting = true
        currentAlert = alert
        presenter.present(alert, animated: true) { [weak self] in
            guard let self = self else { return }
            if self.pendingMessages.first?.id == message.id {
                self.pendingMessages.removeFirst()
            }
        }
    }

    private func scheduleRetryIfUseful() {
        guard !pendingMessages.isEmpty,
              !retryScheduled,
              retryCount < 40 else {
            return
        }
        retryScheduled = true
        retryCount += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self = self else { return }
            self.retryScheduled = false
            self.presentNextIfPossible()
        }
    }

    private func activePresenter() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
        let sceneWindow = scenes
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow }) ??
            scenes.flatMap { $0.windows }.first(where: { !$0.isHidden })
        guard let root = sceneWindow?.rootViewController else { return nil }
        return visibleController(from: root)
    }

    private func visibleController(from controller: UIViewController) -> UIViewController {
        if let presented = controller.presentedViewController,
           !presented.isBeingDismissed {
            return visibleController(from: presented)
        }
        if let navigation = controller as? UINavigationController,
           let visible = navigation.visibleViewController {
            return visibleController(from: visible)
        }
        if let tab = controller as? UITabBarController,
           let selected = tab.selectedViewController {
            return visibleController(from: selected)
        }
        if let split = controller as? UISplitViewController,
           let last = split.viewControllers.last {
            return visibleController(from: last)
        }
        return controller
    }
}
