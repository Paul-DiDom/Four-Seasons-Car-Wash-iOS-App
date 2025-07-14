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
        guard isLoggedIn else {
            debugPrint("Cannot delete account: user is not logged in")
            return
        }
        
        guard let passText = txtPass.text, passText.count >= 6 && passText.count <= 16 else {
            showIt(title: "", msg: "Valid password must be between 6 and 16 characters")
            return
        }
        
        pleaseWait()
        
        Auth.auth().signIn(withEmail: userEmail, password: passText) { authResult, error in
            if let error = error {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.endWait()
                    self.handleFirebaseError(error as NSError)
                }
                return
            }
            
            guard let user = authResult?.user else {
                DispatchQueue.main.async {
                    self.endWait()
                    self.showIt(title: "", msg: "Unexpected login error. Please try again.")
                }
                return
            }
            
            user.getIDTokenResult { idTokenResult, error in
                let token = idTokenResult?.token ?? ""
                
                guard !token.isEmpty else {
                    DispatchQueue.main.async {
                        self.endWait()
                        self.showIt(title: "", msg: "An error occurred. Please try again.")
                    }
                    return
                }
                
                // Prepare request
                let url = URL(string: service + "remove")!
                let payload: [String: String] = ["k": "q9183w", "t": token, "u": user.uid]
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        DispatchQueue.main.async {
                            self.endWait()
                            self.debugPrint("error = \(error)")
                            self.showIt(title: "", msg: "An error occurred. Please try again.")
                        }
                        return
                    }
                    
                    do {
                        guard let rawData = data,
                              let json = try JSONSerialization.jsonObject(with: rawData) as? [String: Any] else {
                            DispatchQueue.main.async {
                                self.endWait()
                                self.showIt(title: "", msg: "Invalid server response.")
                            }
                            return
                        }
                        
                        // Flexible success parsing
                        let goodResult: Bool
                        if let b = json["success"] as? Bool {
                            goodResult = b
                        } else if let i = json["success"] as? Int {
                            goodResult = i == 1
                        } else if let s = json["success"] as? String {
                            goodResult = s == "1" || s.lowercased() == "true"
                        } else {
                            goodResult = false
                        }
                        
                        DispatchQueue.main.async {
                            self.endWait()
                            if goodResult {
                                UserDefaults.standard.set(false, forKey: "loggedIn")
                                UserDefaults.standard.set("",    forKey: "userId")
                                UserDefaults.standard.set("",    forKey: "userEmail")
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                    self.performSegue(withIdentifier: "login", sender: self)
                                }
                            } else {
                                self.showIt(title: "", msg: "An error occurred. Please try again.")
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.endWait()
                            self.showIt(title: "", msg: "Failed to parse server response.")
                        }
                    }
                }
                task.resume()
            }
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
