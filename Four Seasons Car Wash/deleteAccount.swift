import FirebaseAuth
import Foundation

class deleteAccount: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var txtPass: UITextField!
    @IBOutlet weak var lblEmailAddy: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        //password.delegate = self
        //confirmPassword.delegate = self
        debugPrint(userEmail)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setGradientBackground()
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if (isLoggedIn){
            lblEmailAddy.text = userEmail
        }
        else {
            lblEmailAddy.text = ""
        }
    }
    
    @IBAction func btnDeleteAccountTapped(_ sender: Any) {

        // 1. Guard: user logged in
        guard isLoggedIn else {
            //debugPrint("[Delete] Aborted – user is not logged in")
            showAlert(title: "Not logged in", message: "Please sign in first.")
            return
        }

        // 2. Guard: password length
        guard let passText = txtPass.text,
              (6...16).contains(passText.count) else {
            //debugPrint("[Delete] Aborted – password length invalid")
            showAlert(title: "Invalid password",
                      message: "Password must be 6–16 characters.")
            return
        }

        showBusy("Please Wait...")

        // 3. Re-authenticate
        Auth.auth().signIn(withEmail: userEmail, password: passText) { authResult, error in
            if let error = error {
                self.hideBusy()
                //print("[Delete] Firebase sign-in failed:", error.localizedDescription)
                self.handleFirebaseError(error as NSError)
                return
            }

            guard let user = authResult?.user else {
                self.hideBusy()
                //print("[Delete] Unexpected: authResult nil")
                self.showAlert(title: "Login error",
                               message: "Please try again.")
                return
            }

            //print("[Delete] Re-auth OK for uid:", user.uid)

            // 4. Fetch ID token
            user.getIDTokenResult { idTokenResult, error in
                if let error = error {
                    self.hideBusy()
                    //print("[Delete] Token error:", error.localizedDescription)
                    self.showAlert(title: "Token error",
                                   message: "Please try again.")
                    return
                }

                let token = idTokenResult?.token ?? ""
                guard !token.isEmpty else {
                    self.hideBusy()
                    //print("[Delete] Token empty")
                    self.showAlert(title: "Token error",
                                   message: "Please try again.")
                    return
                }

                //print("[Delete] Token retrieved")

                // 5. Build request
                let url = URL(string: service + "remove")!
                let payload = ["k": "q9183w", "t": token, "u": user.uid]
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json; charset=utf-8",
                                 forHTTPHeaderField: "Content-Type")
                request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

                //print("[Delete] Sending request to \(url)")

                // 6. Call API
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        DispatchQueue.main.async {
                            self.hideBusy()
                            //print("[Delete] Network error:", error.localizedDescription)
                            self.showAlert(title: "Network error",
                                           message: "Please try again.")
                        }
                        return
                    }
                    
                    //print("[Delete] Raw response:")
                    if let rawData = data, let responseText = String(data: rawData, encoding: .utf8) {
                        //print(responseText)
                    } else {
                        //print("No data or could not decode as UTF-8")
                    }

                    // 7. Parse response
                    let goodResult: Bool = {
                        guard let raw = data else {
                            //print("[Delete] No response data")
                            return false
                        }

                        do {
                            // First-level JSON
                            guard let top = try JSONSerialization.jsonObject(with: raw) as? [String: Any] else {
                                //print("[Delete] Top-level JSON is not a dictionary")
                                return false
                            }
                            //print("[Delete] Parsed JSON:", top)

                            // ----- unwrap removeResult -----
                            if let nestedString = top["removeResult"] as? String,
                               let nestedData = nestedString.data(using: .utf8),
                               let nested = try JSONSerialization.jsonObject(with: nestedData) as? [String: Any] {

                                //print("[Delete] Nested JSON:", nested)

                                switch nested["success"] {
                                case let b as Bool:   return b
                                case let i as Int:    return i == 1
                                case let s as String: return s == "1" || s.lowercased() == "true"
                                default:              return false
                                }
                            } else {
                                //print("[Delete] 'removeResult' missing or not JSON string")
                            }
                        } catch {
                            //print("[Delete] JSON parsing failed:", error.localizedDescription)
                        }
                        return false
                    }()


                    DispatchQueue.main.async {
                        self.hideBusy()

                        if goodResult {
                            //print("[Delete] Server confirmed delete – logging out")
                            UserDefaults.standard.set(false, forKey: "loggedIn")
                            UserDefaults.standard.removeObject(forKey: "userId")
                            UserDefaults.standard.removeObject(forKey: "userEmail")

                            // ensure UI is idle before segue
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                self.navigateToLogin()
                            }
                        } else {
                            //print("[Delete] Server response indicated failure")
                            self.showAlert(title: "Error",
                                           message: "Account could not be removed.")
                        }
                    }
                }.resume()
            }
        }
    }

    private func showBusy(_ message: String) {
        // replace with whatever HUD you prefer
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
    }

    private func hideBusy() {
        dismiss(animated: true) // dismiss top-most alert
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func navigateToLogin() {
        // If presented modally, dismiss to root first
        if let presented = self.presentedViewController {
            presented.dismiss(animated: false) {
                self.performSegue(withIdentifier: "login", sender: self)
            }
        } else {
            self.performSegue(withIdentifier: "login", sender: self)
        }
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
    
}
