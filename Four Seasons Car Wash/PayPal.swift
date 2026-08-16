import UIKit
import WebKit

final class PayPal: UIViewController, WKNavigationDelegate {
    @IBOutlet private weak var webView: WKWebView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    private var loadingObservation: NSKeyValueObservation?
    private var sessionInvalidationObserver: NSObjectProtocol?
    private var initialNavigation: WKNavigation?
    private var bootstrapErrorWasShown = false
    private var pendingBootstrapError: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        webView.navigationDelegate = self

        activityIndicator.style = .large
        activityIndicator.color = .black
        activityIndicator.hidesWhenStopped = true
        loadingObservation = webView.observe(\.isLoading, options: [.initial, .new]) {
            [weak self] webView, _ in
            if webView.isLoading {
                self?.activityIndicator.startAnimating()
            }
            else {
                self?.activityIndicator.stopAnimating()
            }
        }
        sessionInvalidationObserver = NotificationCenter.default.addObserver(
            forName: .accountSessionDidInvalidate,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.webView.stopLoading()
            self.initialNavigation = nil
            self.showBootstrapError(
                "Your account session changed. Log in again before making a purchase."
            )
        }

        guard let session = AccountSession.currentSnapshot() else {
            showBootstrapError(AccountSession.authenticationUnavailableMessage)
            return
        }

        do {
            let request = try UidHandoff.currentRequest(
                for: .purchase,
                session: session
            )
            guard let navigation = webView.load(request) else {
                showBootstrapError(
                    UidHandoff.HandoffError.invalidRequest.localizedDescription
                )
                return
            }
            initialNavigation = navigation
            UserDefaults.standard.set(true, forKey: "paypal")
            AccountBalanceStore.markRefreshRequired()
        }
        catch {
            showBootstrapError(
                (error as? LocalizedError)?.errorDescription ??
                    "The secure purchase page could not be opened."
            )
        }
    }

    deinit {
        if let sessionInvalidationObserver = sessionInvalidationObserver {
            NotificationCenter.default.removeObserver(sessionInvalidationObserver)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let pendingBootstrapError = pendingBootstrapError {
            showBootstrapError(pendingBootstrapError)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if navigation === initialNavigation {
            initialNavigation = nil
        }
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        handleBootstrapFailure(navigation)
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        handleBootstrapFailure(navigation)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        activityIndicator.stopAnimating()
        showBootstrapError(
            "The purchase page was interrupted. Check your account before trying again."
        )
    }

    private func handleBootstrapFailure(_ navigation: WKNavigation?) {
        guard navigation === initialNavigation else { return }
        initialNavigation = nil
        showBootstrapError(
            "The secure purchase page could not be opened. Please try again."
        )
    }

    private func showBootstrapError(_ message: String) {
        guard !bootstrapErrorWasShown else { return }
        guard viewIfLoaded?.window != nil else {
            pendingBootstrapError = message
            return
        }
        pendingBootstrapError = nil
        bootstrapErrorWasShown = true
        activityIndicator.stopAnimating()

        let alert = UIAlertController(title: "Purchase Unavailable", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }
            if let navigationController = self.navigationController,
               navigationController.viewControllers.first !== self {
                navigationController.popViewController(animated: true)
            }
            else {
                self.dismiss(animated: true, completion: nil)
            }
        })
        present(alert, animated: true, completion: nil)
    }
}
