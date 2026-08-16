import UIKit
import FirebaseAuth

class LoginViewController: UIViewController, UITextFieldDelegate {
        
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    private var passwordResetInProgress = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        self.navigationItem.setHidesBackButton(true, animated: true)
        
        email.delegate = self
        password.delegate = self
        email.textContentType = .emailAddress
        email.keyboardType = .emailAddress
        password.textContentType = .password
        PasswordAuthUI.installVisibilityToggle(on: [password])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if (wasLoggedIn == newOpen){
                
            }
            else if (wasLoggedIn == justLoggedOut){
                self.showIt(title: "Success", msg: "You have been successfully logged out.")
                wasLoggedIn = alreadyLoggedOut
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setGradientBackground()
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        password.text = ""
        PasswordAuthUI.setPasswordFields([password], visible: false)
        PasswordAuthUI.installVisibilityToggle(on: [password])
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @IBAction func btnSignInPressed(_ sender: Any) {
        let normalizedEmail = (email.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let passwordText = password.text ?? ""
        if isValidEmail(normalizedEmail) {
            guard (6...16).contains(passwordText.count) else {
                showIt(
                    title: "",
                    msg: "Password must be between 6 and 16 characters in length"
                )
                return
            }
        }
        else {
            showIt(title: "", msg: "Please enter a valid email address")
            return
        }

        email.text = normalizedEmail
        logIn(email: normalizedEmail, password: passwordText)
    }
    
    @IBAction func btnForgotPasswordPressed(_ sender: Any) {
        if (isConnectedToNetwork()) {
            let alert = UIAlertController(title: "Reset Password", message: "Enter email address", preferredStyle: .alert)
            
            alert.addTextField(configurationHandler: { textFieldEmail in
                textFieldEmail.textContentType = .emailAddress
                textFieldEmail.keyboardType = .emailAddress
                textFieldEmail.autocapitalizationType = .none
                textFieldEmail.autocorrectionType = .no
                textFieldEmail.text = AccountSession.currentSnapshot()?.email ??
                    UserDefaults.standard.string(forKey: "userEmail")
                textFieldEmail.placeholder = "email"
            })

            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
                [weak self, weak alert] _ in
                guard let self = self,
                      let enteredEmail = alert?.textFields?.first?.text else {
                    return
                }
                let normalizedEmail = enteredEmail
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard self.isValidEmail(normalizedEmail) else {
                    self.showIt(title: "", msg: "Please enter a valid email address")
                    return
                }
                self.resetPassword(email: normalizedEmail)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel,handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    func resetPassword(email: String) {
        guard !passwordResetInProgress else { return }
        passwordResetInProgress = true
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.passwordResetInProgress = false
                if let error = error {
                    self.handleFirebaseError(error as NSError)
                }
                else {
                    self.showIt(
                        title: "Success",
                        msg: "A link to reset your password has been sent to " + email
                    )
                }
            }
        }
    }
    
    @IBAction func btnAsGuestClicked(_ sender: Any) {
        returnToExistingHome()
    }
        
    @IBAction func btnSignUpClicked(_ sender: Any) {
        self.performSegue(withIdentifier: "register", sender: self)
    }
    
    func setGradientBackground() {
        let colorTop =  UIColor(red: 222.0/255.0, green: 222.0/255.0, blue: 222.0/255.0, alpha: 1.0).cgColor
        let colorBottom = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0).cgColor
                    
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorTop, colorBottom]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = self.view.bounds
                
        self.view.layer.insertSublayer(gradientLayer, at:0)
    }
    
//    func isValidPhone(number:String) -> Bool {
//        if (number.isEmpty || number.count == 0) {
//            return true
//        }
//        else if (number.count > 9 && number.count < 13) {
//            return true
//        }
//        return false
//    }
    
    func checkUser() {
        if (Auth.auth().currentUser) != nil {
            //print("User has signed in")
        } else {
            //print("No user is signed in.")
        }
    }
}


extension LoginViewController {
   func textFieldShouldReturn(_ textField: UITextField) -> Bool {
      return textField.resignFirstResponder()
   }
}
