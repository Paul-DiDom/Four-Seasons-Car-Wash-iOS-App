import UIKit
import WebKit

final class myAccount: UIViewController, WKNavigationDelegate {
    @IBOutlet private weak var webView: WKWebView!
    @IBOutlet private var btnChangePass: UIButton!
    @IBOutlet private var emailText: UILabel!

    private var sessionInvalidationObserver: NSObjectProtocol?
    private var initialNavigation: WKNavigation?
    private var bootstrapErrorWasShown = false
    private var pendingBootstrapError: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        ViewController.fixButton(btnChangePass)
        webView.navigationDelegate = self

        sessionInvalidationObserver = NotificationCenter.default.addObserver(
            forName: .accountSessionDidInvalidate,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.webView.stopLoading()
            self.initialNavigation = nil
            self.btnChangePass.isEnabled = false
            self.showBootstrapError(
                "Your account session changed. Log in again to view account activity."
            )
        }

        guard let session = AccountSession.currentSnapshot() else {
            btnChangePass.isEnabled = false
            showBootstrapError(AccountSession.authenticationUnavailableMessage)
            return
        }

        emailText.text = session.email
        do {
            let request = try UidHandoff.currentRequest(
                for: .transactions,
                session: session
            )
            guard let navigation = webView.load(request) else {
                showBootstrapError(
                    UidHandoff.HandoffError.invalidRequest.localizedDescription
                )
                return
            }
            initialNavigation = navigation
            UserDefaults.standard.set(true, forKey: "checkBalance")
        }
        catch {
            showBootstrapError(
                (error as? LocalizedError)?.errorDescription ??
                    "Your account activity could not be opened."
            )
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let pendingBootstrapError = pendingBootstrapError {
            showBootstrapError(pendingBootstrapError)
        }
        if webView.isLoading {
            view.makeToast(message: "Getting Transactions \nPlease Wait...")
        }
    }

    deinit {
        if let sessionInvalidationObserver = sessionInvalidationObserver {
            NotificationCenter.default.removeObserver(sessionInvalidationObserver)
        }
    }

    @IBAction private func btnChangePassClicked(_ sender: AnyObject) {
        guard AccountSession.currentSnapshot() != nil else {
            showIt(
                title: "Account Unavailable",
                message: AccountSession.authenticationUnavailableMessage
            )
            return
        }

        let passwordController = PasswordChangeViewController()
        passwordController.modalPresentationStyle = .formSheet
        passwordController.onPasswordChanged = { [weak self] in
            self?.showIt(
                title: "Success",
                message: "Your password has been updated."
            )
        }
        present(passwordController, animated: true, completion: nil)
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
        showBootstrapError(
            "The account page was interrupted. Return and open My Account again."
        )
    }

    private func handleBootstrapFailure(_ navigation: WKNavigation?) {
        guard navigation === initialNavigation else { return }
        initialNavigation = nil
        showBootstrapError(
            "Your account activity could not be opened. Please try again."
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
        showIt(title: "Account Unavailable", message: message)
    }

    private func showIt(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true, completion: nil)
    }
}
