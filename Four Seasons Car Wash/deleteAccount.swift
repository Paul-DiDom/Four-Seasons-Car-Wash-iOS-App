import FirebaseAuth
import Foundation
import UIKit

final class deleteAccount: UIViewController, UITextFieldDelegate {
    @IBOutlet private weak var txtPass: UITextField!
    @IBOutlet private weak var lblEmailAddy: UILabel!

    private var activeRequestID: UUID?
    private weak var deleteButton: UIButton?
    private weak var busyAlert: UIAlertController?

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        txtPass.delegate = self
        txtPass.textContentType = .password
        PasswordAuthUI.installVisibilityToggle(on: [txtPass])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setGradientBackground()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lblEmailAddy.text = AccountSession.currentSnapshot()?.email ?? ""
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        activeRequestID = nil
        clearPassword()
    }

    @IBAction private func btnDeleteAccountTapped(_ sender: Any) {
        guard activeRequestID == nil else { return }
        guard let session = AccountSession.currentSnapshot(),
              let currentUser = Auth.auth().currentUser,
              currentUser.uid == session.userID,
              let accountEmail = currentUser.email,
              !accountEmail.isEmpty else {
            showAlert(
                title: "Account unavailable",
                message: "Please log out, log in, and try again."
            )
            return
        }
        guard let password = txtPass.text,
              (6...16).contains(password.count) else {
            showAlert(
                title: "Invalid password",
                message: "Password must be 6–16 characters."
            )
            return
        }

        let requestID = UUID()
        activeRequestID = requestID
        deleteButton = sender as? UIButton
        deleteButton?.isEnabled = false
        showBusy("Please Wait...")

        let credential = EmailAuthProvider.credential(
            withEmail: accountEmail,
            password: password
        )
        currentUser.reauthenticate(with: credential) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self,
                      self.activeRequestID == requestID else {
                    return
                }
                if let error = error {
                    self.finishRequest(clearPassword: true) {
                        self.handleFirebaseError(error as NSError)
                    }
                    return
                }
                guard result?.user.uid == session.userID,
                      Auth.auth().currentUser?.uid == session.userID,
                      AccountSession.isCurrent(session) else {
                    self.finishRequest(clearPassword: true) {
                        self.showSessionChangedError()
                    }
                    return
                }

                currentUser.getIDTokenResult { [weak self] tokenResult, error in
                    DispatchQueue.main.async {
                        guard let self = self,
                              self.activeRequestID == requestID else {
                            return
                        }
                        if error != nil {
                            self.finishRequest(clearPassword: true) {
                                self.showAlert(
                                    title: "Token error",
                                    message: "Please try again."
                                )
                            }
                            return
                        }
                        guard let token = tokenResult?.token,
                              !token.isEmpty,
                              Auth.auth().currentUser?.uid == session.userID,
                              AccountSession.isCurrent(session) else {
                            self.finishRequest(clearPassword: true) {
                                self.showSessionChangedError()
                            }
                            return
                        }
                        self.sendDeleteRequest(
                            token: token,
                            session: session,
                            requestID: requestID
                        )
                    }
                }
            }
        }
    }

    private func sendDeleteRequest(
        token: String,
        session: AccountSession.Snapshot,
        requestID: UUID
    ) {
        guard activeRequestID == requestID,
              AccountSession.isCurrent(session),
              let url = URL(string: service + "remove"),
              let body = try? JSONSerialization.data(withJSONObject: [
                  "k": "q9183w",
                  "t": token,
                  "u": session.userID
              ]) else {
            finishRequest(clearPassword: true) { [weak self] in
                self?.showSessionChangedError()
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "application/json; charset=utf-8",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            let success = error == nil &&
                (response as? HTTPURLResponse)?.statusCode == 200 &&
                Self.parseDeleteSuccess(data)

            DispatchQueue.main.async {
                guard let self = self,
                      self.activeRequestID == requestID else {
                    return
                }
                guard AccountSession.isCurrent(session),
                      Auth.auth().currentUser?.uid == session.userID else {
                    self.finishRequest(clearPassword: true) {
                        self.showSessionChangedError()
                    }
                    return
                }

                if success {
                    AccountSession.completeAccountDeletion { [weak self] cleanupSucceeded in
                        guard let self = self else { return }
                        self.finishRequest(clearPassword: true) {
                            if cleanupSucceeded {
                                self.navigateToLogin()
                            }
                            else {
                                self.showAlert(
                                    title: "Secure cleanup incomplete",
                                    message: "Your account was removed, but the previous secure session could not be cleared. Please restart the app before logging in."
                                )
                            }
                        }
                    }
                }
                else {
                    self.finishRequest(clearPassword: false) {
                        self.showAlert(
                            title: "Error",
                            message: "Account could not be removed."
                        )
                    }
                }
            }
        }.resume()
    }

    private static func parseDeleteSuccess(_ data: Data?) -> Bool {
        guard let data = data,
              let top = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let nestedString = top["removeResult"] as? String,
              let nestedData = nestedString.data(using: .utf8),
              let nested = try? JSONSerialization.jsonObject(with: nestedData) as? [String: Any] else {
            return false
        }

        switch nested["success"] {
        case let value as Bool:
            return value
        case let value as Int:
            return value == 1
        case let value as String:
            return value == "1" || value.lowercased() == "true"
        default:
            return false
        }
    }

    private func showBusy(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        busyAlert = alert
        present(alert, animated: true, completion: nil)
    }

    private func finishRequest(
        clearPassword shouldClearPassword: Bool,
        completion: (() -> Void)? = nil
    ) {
        activeRequestID = nil
        deleteButton?.isEnabled = true
        if shouldClearPassword {
            clearPassword()
        }
        let alert = busyAlert
        busyAlert = nil
        if let alert = alert {
            alert.dismiss(animated: false, completion: completion)
        }
        else {
            completion?()
        }
    }

    private func clearPassword() {
        txtPass?.text = ""
        if let txtPass = txtPass {
            PasswordAuthUI.setPasswordFields([txtPass], visible: false)
            PasswordAuthUI.installVisibilityToggle(on: [txtPass])
        }
    }

    private func showSessionChangedError() {
        showAlert(
            title: "Account session changed",
            message: "Please log out, log in, and try again."
        )
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true, completion: nil)
    }

    private func navigateToLogin() {
        if let presented = presentedViewController {
            presented.dismiss(animated: false) { [weak self] in
                self?.performSegue(withIdentifier: "login", sender: self)
            }
        }
        else {
            performSegue(withIdentifier: "login", sender: self)
        }
    }

    private func setGradientBackground() {
        let colorTop = UIColor(
            red: 222.0 / 255.0,
            green: 222.0 / 255.0,
            blue: 222.0 / 255.0,
            alpha: 1.0
        ).cgColor
        let colorBottom = UIColor.white.cgColor
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorTop, colorBottom]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
