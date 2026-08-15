//
//  webby.swift
//  Nanak Car Wash
//
//  Created by Paul Di Domenico on 2020-06-23.
//  Copyright © 2020 Tech1st Wash Systems. All rights reserved.
//

import UIKit
import WebKit

final class webby: UIViewController, WKNavigationDelegate {
    @IBOutlet private weak var webView: WKWebView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    var handoffDestination: UidHandoff.Destination?

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

        if let destination = handoffDestination {
            configurePrivateHandoff(for: destination)
        }
        else {
            configureGenericPage()
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
            showPageError(pendingBootstrapError)
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
        handleInitialFailure(navigation)
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        handleInitialFailure(navigation)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        activityIndicator.stopAnimating()
        guard handoffDestination != nil else { return }
        showPageError(
            "The secure page was interrupted. Return and open it again."
        )
    }

    private func configurePrivateHandoff(for destination: UidHandoff.Destination) {
        sessionInvalidationObserver = NotificationCenter.default.addObserver(
            forName: .accountSessionDidInvalidate,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.webView.stopLoading()
            self.initialNavigation = nil
            self.showPageError(
                "Your account session changed. Log in again before opening this page."
            )
        }

        guard let session = AccountSession.currentSnapshot() else {
            showPageError(AccountSession.authenticationUnavailableMessage)
            return
        }

        do {
            let request = try UidHandoff.currentRequest(
                for: destination,
                session: session
            )
            guard let navigation = webView.load(request) else {
                showPageError(
                    UidHandoff.HandoffError.invalidRequest.localizedDescription
                )
                return
            }
            initialNavigation = navigation
            UserDefaults.standard.set(true, forKey: "checkBalance")
        }
        catch {
            showPageError(
                (error as? LocalizedError)?.errorDescription ??
                    "The secure page could not be opened."
            )
        }
    }

    private func configureGenericPage() {
        guard let url = URL(string: ViewController.theUrl) else {
            showPageError("This page could not be opened.")
            return
        }
        initialNavigation = webView.load(URLRequest(url: url))
    }

    private func handleInitialFailure(_ navigation: WKNavigation?) {
        guard navigation === initialNavigation else { return }
        initialNavigation = nil
        showPageError("This page could not be opened. Please try again.")
    }

    private func showPageError(_ message: String) {
        guard !bootstrapErrorWasShown else { return }
        guard viewIfLoaded?.window != nil else {
            pendingBootstrapError = message
            return
        }
        pendingBootstrapError = nil
        bootstrapErrorWasShown = true
        activityIndicator.stopAnimating()

        let alert = UIAlertController(title: "Page Unavailable", message: message, preferredStyle: .alert)
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
