import FirebaseAuth
import UIKit

enum PasswordAuthUI {
    private final class WeakPasswordField {
        weak var value: UITextField?

        init(_ value: UITextField) {
            self.value = value
        }
    }

    static let brandPrimary = UIColor(
        red: 0x30 / 255.0,
        green: 0x3F / 255.0,
        blue: 0x9F / 255.0,
        alpha: 1.0
    )

    static func colorImage(_ color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1.0, height: 1.0))
        return renderer.image { context in
            context.cgContext.setFillColor(color.cgColor)
            context.cgContext.fill(CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0))
        }
    }

    static func installVisibilityToggle(
        on fields: [UITextField],
        anchor: UITextField? = nil
    ) {
        let passwordFields = fields
        guard !passwordFields.isEmpty,
              let anchorField = anchor ?? passwordFields.last else {
            return
        }

        setPasswordFields(passwordFields, visible: false)
        let weakFields = passwordFields.map(WeakPasswordField.init)
        let toggleButton = UIButton(type: .system)
        toggleButton.frame = CGRect(x: 0.0, y: 0.0, width: 44.0, height: 44.0)
        toggleButton.tintColor = brandPrimary
        toggleButton.accessibilityIdentifier = "password.visibilityToggle"
        configureVisibilityButton(
            toggleButton,
            visible: false,
            fieldCount: passwordFields.count
        )
        toggleButton.addAction(UIAction { [weak toggleButton] _ in
            guard let toggleButton = toggleButton else { return }
            let currentFields = weakFields.compactMap { $0.value }
            guard !currentFields.isEmpty else { return }
            let showPasswords = currentFields.contains { $0.isSecureTextEntry }
            setPasswordFields(currentFields, visible: showPasswords)
            configureVisibilityButton(
                toggleButton,
                visible: showPasswords,
                fieldCount: currentFields.count
            )
        }, for: .touchUpInside)

        anchorField.rightView = toggleButton
        anchorField.rightViewMode = .always
    }

    static func configureVisibilityButton(
        _ button: UIButton,
        visible: Bool,
        fieldCount: Int
    ) {
        button.setImage(
            UIImage(systemName: visible ? "eye.slash" : "eye"),
            for: .normal
        )
        button.accessibilityLabel = visible
            ? (fieldCount == 1 ? "Hide password" : "Hide passwords")
            : (fieldCount == 1 ? "Show password" : "Show passwords")
        button.accessibilityHint = fieldCount == 1
            ? "Shows or hides the password."
            : "Shows or hides all password fields."
        button.accessibilityValue = visible ? "Shown" : "Hidden"
    }

    static func setPasswordFields(_ fields: [UITextField], visible: Bool) {
        fields.forEach { textField in
            let existingText = textField.text
            let selectionOffsets: (start: Int, end: Int)?
            if let selectedRange = textField.selectedTextRange {
                selectionOffsets = (
                    textField.offset(
                        from: textField.beginningOfDocument,
                        to: selectedRange.start
                    ),
                    textField.offset(
                        from: textField.beginningOfDocument,
                        to: selectedRange.end
                    )
                )
            }
            else {
                selectionOffsets = nil
            }

            textField.isSecureTextEntry = !visible
            textField.text = existingText

            if let selectionOffsets = selectionOffsets,
               let start = textField.position(
                   from: textField.beginningOfDocument,
                   offset: selectionOffsets.start
               ),
               let end = textField.position(
                   from: textField.beginningOfDocument,
                   offset: selectionOffsets.end
               ) {
                textField.selectedTextRange = textField.textRange(from: start, to: end)
            }
        }
    }
}

final class PasswordChangeViewController: UIViewController, UITextFieldDelegate {
    var onPasswordChanged: (() -> Void)?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let titleLabel = UILabel()
    private let instructionsLabel = UILabel()
    private let statusLabel = UILabel()
    private let currentPasswordField = UITextField()
    private let newPasswordField = UITextField()
    private let confirmPasswordField = UITextField()
    private let visibilityButton = UIButton(type: .system)
    private let updateButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private var keyboardObservers: [NSObjectProtocol] = []
    private var sessionInvalidationObserver: NSObjectProtocol?
    private var passwordsVisible = false
    private var activeRequestID: UUID?

    private var passwordFields: [UITextField] {
        [currentPasswordField, newPasswordField, confirmPasswordField]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureFields()
        configureControls()
        buildLayout()
        observeKeyboard()
        sessionInvalidationObserver = NotificationCenter.default.addObserver(
            forName: .accountSessionDidInvalidate,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.activeRequestID = nil
            self.setBusy(false)
            self.clearPasswords()
            self.dismiss(animated: true, completion: nil)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        activeRequestID = nil
        clearPasswords()
    }

    deinit {
        keyboardObservers.forEach(NotificationCenter.default.removeObserver)
        if let sessionInvalidationObserver = sessionInvalidationObserver {
            NotificationCenter.default.removeObserver(sessionInvalidationObserver)
        }
    }

    private func configureView() {
        view.backgroundColor = .systemBackground
        overrideUserInterfaceStyle = .light
        preferredContentSize = CGSize(width: 420.0, height: 590.0)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = false
        scrollView.keyboardDismissMode = .interactive

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 16.0

        titleLabel.text = "Change Password"
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        instructionsLabel.text = "Enter your current password, then choose a new password."
        instructionsLabel.font = .preferredFont(forTextStyle: .body)
        instructionsLabel.adjustsFontForContentSizeCategory = true
        instructionsLabel.textColor = .secondaryLabel
        instructionsLabel.numberOfLines = 0

        statusLabel.font = .preferredFont(forTextStyle: .callout)
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.numberOfLines = 0
        statusLabel.isHidden = true
        statusLabel.accessibilityIdentifier = "passwordChange.status"
    }

    private func configureFields() {
        configurePasswordField(
            currentPasswordField,
            contentType: .password,
            returnKeyType: .next,
            accessibilityIdentifier: "passwordChange.current"
        )
        configurePasswordField(
            newPasswordField,
            contentType: .newPassword,
            returnKeyType: .next,
            accessibilityIdentifier: "passwordChange.new"
        )
        configurePasswordField(
            confirmPasswordField,
            contentType: .newPassword,
            returnKeyType: .done,
            accessibilityIdentifier: "passwordChange.confirm"
        )
    }

    private func configurePasswordField(
        _ textField: UITextField,
        contentType: UITextContentType,
        returnKeyType: UIReturnKeyType,
        accessibilityIdentifier: String
    ) {
        textField.borderStyle = .roundedRect
        textField.font = .preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.isSecureTextEntry = true
        textField.textContentType = contentType
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.returnKeyType = returnKeyType
        textField.enablesReturnKeyAutomatically = true
        textField.delegate = self
        textField.accessibilityIdentifier = accessibilityIdentifier
        textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 48.0).isActive = true
    }

    private func configureControls() {
        visibilityButton.translatesAutoresizingMaskIntoConstraints = false
        visibilityButton.tintColor = PasswordAuthUI.brandPrimary
        visibilityButton.accessibilityIdentifier = "password.visibilityToggle"
        visibilityButton.addTarget(
            self,
            action: #selector(togglePasswordVisibility),
            for: .touchUpInside
        )
        PasswordAuthUI.configureVisibilityButton(
            visibilityButton,
            visible: false,
            fieldCount: passwordFields.count
        )
        NSLayoutConstraint.activate([
            visibilityButton.widthAnchor.constraint(equalToConstant: 48.0),
            visibilityButton.heightAnchor.constraint(equalToConstant: 48.0)
        ])

        configureActionButton(cancelButton, title: "Cancel", filled: false)
        cancelButton.accessibilityIdentifier = "passwordChange.cancel"
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        configureActionButton(updateButton, title: "Update Password", filled: true)
        updateButton.accessibilityIdentifier = "passwordChange.update"
        updateButton.addTarget(self, action: #selector(updateTapped), for: .touchUpInside)
    }

    private func configureActionButton(_ button: UIButton, title: String, filled: Bool) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.layer.cornerRadius = 10.0
        button.clipsToBounds = true
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 48.0).isActive = true

        if filled {
            button.setTitleColor(.white, for: .normal)
            button.setTitleColor(.systemGray, for: .disabled)
            button.setBackgroundImage(
                PasswordAuthUI.colorImage(PasswordAuthUI.brandPrimary),
                for: .normal
            )
            button.setBackgroundImage(
                PasswordAuthUI.colorImage(.systemGray4),
                for: .disabled
            )
        }
        else {
            button.setTitleColor(PasswordAuthUI.brandPrimary, for: .normal)
            button.setTitleColor(.systemGray, for: .disabled)
            button.setBackgroundImage(
                PasswordAuthUI.colorImage(.secondarySystemBackground),
                for: .normal
            )
            button.setBackgroundImage(
                PasswordAuthUI.colorImage(.systemGray6),
                for: .disabled
            )
            button.layer.borderWidth = 1.5
            button.layer.borderColor = PasswordAuthUI.brandPrimary.cgColor
        }
    }

    private func buildLayout() {
        let headerStack = UIStackView(arrangedSubviews: [titleLabel, visibilityButton])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = 8.0

        let buttonsStack = UIStackView(arrangedSubviews: [updateButton, cancelButton])
        buttonsStack.axis = .vertical
        buttonsStack.alignment = .fill
        buttonsStack.spacing = 8.0

        contentStack.addArrangedSubview(headerStack)
        contentStack.addArrangedSubview(instructionsLabel)
        contentStack.addArrangedSubview(
            makeLabeledField(title: "Current password", textField: currentPasswordField)
        )
        contentStack.addArrangedSubview(
            makeLabeledField(title: "New password", textField: newPasswordField)
        )
        contentStack.addArrangedSubview(
            makeLabeledField(title: "Confirm new password", textField: confirmPasswordField)
        )
        contentStack.addArrangedSubview(statusLabel)
        contentStack.addArrangedSubview(buttonsStack)

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.topAnchor,
                constant: 24.0
            ),
            contentStack.leadingAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.leadingAnchor,
                constant: 20.0
            ),
            contentStack.trailingAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.trailingAnchor,
                constant: -20.0
            ),
            contentStack.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                constant: -24.0
            )
        ])
    }

    private func makeLabeledField(title: String, textField: UITextField) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        label.numberOfLines = 0
        textField.accessibilityLabel = title

        let stack = UIStackView(arrangedSubviews: [label, textField])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 6.0
        return stack
    }

    private func observeKeyboard() {
        let center = NotificationCenter.default
        keyboardObservers.append(center.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.updateKeyboardInsets(notification)
        })
        keyboardObservers.append(center.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.scrollView.contentInset.bottom = 0.0
            self?.scrollView.verticalScrollIndicatorInsets.bottom = 0.0
        })
    }

    private func updateKeyboardInsets(_ notification: Notification) {
        guard let screenFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                as? CGRect else {
            return
        }
        let keyboardFrame = view.convert(screenFrame, from: nil)
        let overlap = max(0.0, view.bounds.maxY - keyboardFrame.minY - view.safeAreaInsets.bottom)
        scrollView.contentInset.bottom = overlap
        scrollView.verticalScrollIndicatorInsets.bottom = overlap
    }

    @objc private func togglePasswordVisibility() {
        passwordsVisible.toggle()
        PasswordAuthUI.setPasswordFields(passwordFields, visible: passwordsVisible)
        PasswordAuthUI.configureVisibilityButton(
            visibilityButton,
            visible: passwordsVisible,
            fieldCount: passwordFields.count
        )
    }

    @objc private func cancelTapped() {
        guard activeRequestID == nil else { return }
        clearPasswords()
        dismiss(animated: true, completion: nil)
    }

    @objc private func updateTapped() {
        guard activeRequestID == nil else { return }

        let currentPassword = currentPasswordField.text ?? ""
        let newPassword = newPasswordField.text ?? ""
        let confirmPassword = confirmPasswordField.text ?? ""

        guard !currentPassword.isEmpty else {
            showError("Enter your current password.", focus: currentPasswordField)
            return
        }
        guard (6...16).contains(newPassword.count) else {
            showError(
                "Password must be between 6 and 16 characters in length.",
                focus: newPasswordField
            )
            return
        }
        guard newPassword == confirmPassword else {
            showError("The new passwords do not match.", focus: confirmPasswordField)
            return
        }
        guard currentPassword != newPassword else {
            showError(
                "Choose a password different from your current password.",
                focus: newPasswordField
            )
            return
        }
        guard let session = AccountSession.currentSnapshot(),
              let currentUser = Auth.auth().currentUser,
              let accountEmail = currentUser.email,
              !accountEmail.isEmpty,
              currentUser.uid == session.userID else {
            showAccountSessionError()
            return
        }

        let requestID = UUID()
        let expectedUID = currentUser.uid
        activeRequestID = requestID
        setBusy(true)

        let credential = EmailAuthProvider.credential(
            withEmail: accountEmail,
            password: currentPassword
        )
        currentUser.reauthenticate(with: credential) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self, self.activeRequestID == requestID else { return }

                if let error = error {
                    self.finishRequest()
                    self.handleReauthenticationError(error)
                    return
                }
                guard let reauthenticatedUID = result?.user.uid,
                      reauthenticatedUID == expectedUID,
                      AccountSession.isCurrent(session),
                      Auth.auth().currentUser?.uid == expectedUID else {
                    self.finishRequest()
                    self.showAccountSessionError()
                    return
                }

                currentUser.updatePassword(to: newPassword) { [weak self] error in
                    DispatchQueue.main.async {
                        guard let self = self, self.activeRequestID == requestID else { return }

                        guard AccountSession.isCurrent(session),
                              Auth.auth().currentUser?.uid == expectedUID else {
                            self.finishRequest()
                            self.showAccountSessionError()
                            return
                        }
                        if let error = error {
                            self.finishRequest()
                            self.handlePasswordUpdateError(error)
                            return
                        }
                        self.activeRequestID = nil
                        self.setBusy(false)
                        self.clearPasswords()
                        let completion = self.onPasswordChanged
                        self.dismiss(animated: true, completion: completion)
                    }
                }
            }
        }
    }

    private func finishRequest() {
        activeRequestID = nil
        setBusy(false)
    }

    private func setBusy(_ busy: Bool) {
        passwordFields.forEach { $0.isEnabled = !busy }
        visibilityButton.isEnabled = !busy
        updateButton.isEnabled = !busy
        cancelButton.isEnabled = !busy
        isModalInPresentation = busy
        updateButton.setTitle(busy ? "Updating Password..." : "Update Password", for: .normal)

        if busy {
            let progressMessage = "Verifying your current password..."
            statusLabel.text = progressMessage
            statusLabel.textColor = .secondaryLabel
            statusLabel.accessibilityLabel = progressMessage
            statusLabel.isHidden = false
            UIAccessibility.post(notification: .announcement, argument: progressMessage)
        }
        else {
            statusLabel.isHidden = true
            statusLabel.accessibilityLabel = nil
        }
    }

    private func handleReauthenticationError(_ error: Error) {
        guard let errorCode = AuthErrorCode(rawValue: (error as NSError).code) else {
            showError("Could not verify your current password. Please try again.")
            return
        }

        switch errorCode {
        case .wrongPassword, .invalidCredential:
            currentPasswordField.text = ""
            showError("The current password is incorrect.", focus: currentPasswordField)
        case .networkError:
            showError("Could not verify your password. Check your connection and try again.")
        case .tooManyRequests:
            showError("Too many attempts were made. Please wait and try again.")
        case .userMismatch, .userNotFound, .userDisabled, .invalidUserToken, .userTokenExpired:
            showAccountSessionError()
        default:
            showError("Could not verify your current password. Please try again.")
        }
    }

    private func handlePasswordUpdateError(_ error: Error) {
        guard let errorCode = AuthErrorCode(rawValue: (error as NSError).code) else {
            showError("Your password could not be updated. Please try again.")
            return
        }

        switch errorCode {
        case .weakPassword:
            let failureReason = (error as NSError).userInfo[NSLocalizedFailureReasonErrorKey]
                as? String
            let message = failureReason?.trimmingCharacters(in: .whitespacesAndNewlines)
            showError(
                message.flatMap { $0.isEmpty ? nil : $0 } ?? "Choose a stronger password.",
                focus: newPasswordField
            )
        case .requiresRecentLogin:
            currentPasswordField.text = ""
            showError(
                "Firebase could not verify the recent login. Enter your current password and try again.",
                focus: currentPasswordField
            )
        case .networkError:
            showError("Your password could not be updated. Check your connection and try again.")
        case .tooManyRequests:
            showError("Too many attempts were made. Please wait and try again.")
        case .userMismatch, .userNotFound, .userDisabled, .invalidUserToken, .userTokenExpired:
            showAccountSessionError()
        default:
            showError("Your password could not be updated. Please try again.")
        }
    }

    private func showAccountSessionError() {
        currentPasswordField.text = ""
        showError(
            "Your account session changed. Please log out and log in again before changing your password."
        )
    }

    private func showError(_ message: String, focus textField: UITextField? = nil) {
        statusLabel.text = message
        statusLabel.textColor = .systemRed
        statusLabel.isHidden = false
        statusLabel.accessibilityLabel = "Error: \(message)"

        DispatchQueue.main.async {
            textField?.becomeFirstResponder()
            UIAccessibility.post(
                notification: .layoutChanged,
                argument: textField ?? self.statusLabel
            )
        }
    }

    private func clearPasswords() {
        passwordFields.forEach { $0.text = "" }
        passwordsVisible = false
        PasswordAuthUI.setPasswordFields(passwordFields, visible: false)
        PasswordAuthUI.configureVisibilityButton(
            visibilityButton,
            visible: false,
            fieldCount: passwordFields.count
        )
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === currentPasswordField {
            newPasswordField.becomeFirstResponder()
        }
        else if textField === newPasswordField {
            confirmPasswordField.becomeFirstResponder()
        }
        else {
            textField.resignFirstResponder()
            updateTapped()
        }
        return true
    }
}
