import UIKit
import Foundation
import Foundation
import FirebaseAuth

class Register: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var phoneNumber: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var confirmEmail: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var confirmPassword: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        
        password.delegate = self
        confirmPassword.delegate = self
        checkFreeCodeOffer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setGradientBackground()
        super.viewWillAppear(animated)
    }
    
    
    @IBAction func btnRegisterTapped(_ sender: Any) {
        let firstNameText = firstName.text!
        let lastNameText = lastName.text!
        let phoneNumberText = phoneNumber.text!
        let emailText = email.text!
        let confirmEmailText = confirmEmail.text!
        let passwordText = password.text!
        let confirmPasswordText = confirmPassword.text!
        
        //        print (firstNameText)
        //        print (lastNameText)
        //        print (phoneNumberText)
        //        print (emailText)
        //        print (confirmEmailText)
        //        print (passwordText)
        //        print (confirmPasswordText)
        
        var fixedPhoneNum = phoneNumberText.trimmingCharacters(in: .whitespacesAndNewlines)
        fixedPhoneNum = fixedPhoneNum.replacingOccurrences(of: " ", with: "")
        fixedPhoneNum = fixedPhoneNum.replacingOccurrences(of: "-", with: "")
        fixedPhoneNum = fixedPhoneNum.replacingOccurrences(of: ".", with: "")
        fixedPhoneNum = fixedPhoneNum.replacingOccurrences(of: "(", with: "")
        fixedPhoneNum = fixedPhoneNum.replacingOccurrences(of: ")", with: "")
        
        if (firstNameText.count < 1){
            showIt(title: "", msg: "Please enter First Name")
            return
        }
        else if (lastNameText.count < 1){
            showIt(title: "", msg: "Please enter Last Name")
            return
        }
        if (!fixedPhoneNum.isEmpty && !isValidPhone(number: fixedPhoneNum)) {
            showIt(title: "", msg: "Please enter a valid phone number")
            return
        }
        else if (!isValidEmail(emailText)){
            showIt(title: "", msg: "Please enter a vaild email address")
            return
        }
        else if (emailText != confirmEmailText){
            showIt(title: "", msg: "Email and confirm email address do not match")
            return
        }
        else if (passwordText.count < 6 || passwordText.count > 16){
            showIt(title: "", msg: "Valid password must be between 6 and 16 characters")
            return
        }
        else if (passwordText != confirmPasswordText){
            showIt(title: "", msg: "Password and Confirm Password do not match")
            return
        }
        
        var jsonBody: [String: Any]

        if (fixedPhoneNum.count > 8) {
            jsonBody = [
                "firstName": firstNameText,
                "lastName": lastNameText,
                "phone": fixedPhoneNum,
                "email": emailText,
                "password": passwordText,
                "l": getSite()
            ]
        } else {
            jsonBody = [
                "firstName": firstNameText,
                "lastName": lastNameText,
                "email": emailText,
                "password": passwordText,
                "l": getSite()
            ]
        }
        
        let urlString = service + "rver2"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: jsonBody)
        
        pleaseWait()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { DispatchQueue.main.async { self.endWait() } }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.showIt(title: "Oops!", msg: error.localizedDescription)
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let data = data else {
                DispatchQueue.main.async {
                    self.showIt(title: "Oops!", msg: "Server error. Please try again.")
                }
                return
            }
            
            do {
                // Parse outer response
                guard
                    let outer = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let outerString = outer["rver2Result"] as? String,
                    let innerData = outerString.data(using: .utf8),
                    let inner = try JSONSerialization.jsonObject(with: innerData) as? [String: Any]
                else {
                    DispatchQueue.main.async {
                        self.showIt(title: "Oops!", msg: "Unexpected response format.")
                    }
                    return
                }
                
                if myDebug {
                    print("register() result =", inner)
                }
                
                let success = (inner["success"] as? String)?.lowercased() == "true"
                self.endWait()
                if success {
                    let userId = inner["localId"] as? String ?? ""
                    UserDefaults.standard.set(true, forKey: "freeCodeGiven")
                    self.logIn(email: emailText, password: passwordText)
                    
                } else {
                    let errorCode = inner["error"] as? String ?? ""
                    let message = Self.friendlyMessage(for: errorCode)
                    DispatchQueue.main.async {
                        self.showIt(title: "Registration Failed", msg: message)
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.showIt(title: "Oops!", msg: "Failed to parse server response.")
                }
            }
        }
        
        task.resume()
    }
    
    func checkFreeCodeOffer() {
        if UserDefaults.standard.bool(forKey: "freeCodeGiven") {
            return
        }

        guard let url = URL(string: service + "f") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [:], options: [])

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil, let data = data else { return }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let result = json["fResult"] as? String,
                   result == "1" {
                    DispatchQueue.main.async {
                        self.showFreeCodeMessage()
                    }
                }
            } catch {
                if (myDebug){
                    self.debugPrint("checkFreeCodeOffer()")
                }
            }
        }
        task.resume()
    }

    
    func showFreeCodeMessage() {
        let alert = UIAlertController(
            title: "✅ Try our app for FREE!",
            message: """
            To receive a FREE $4 wash code for use in the COIN BAYS, please enter your phone number. This will also allow you to receive alerts about promotions.

            You may register without a phone number if you prefer.
            """,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    
    /// Convert technical error codes to user-friendly text
    private static func friendlyMessage(for code: String) -> String {
        switch code {
        case "EMAIL_EXISTS":
            return "An account with this email already exists. Please log in or use another email."
        case "WEAK_PASSWORD":
            return "Password is too weak. Please choose a stronger password."
        case "INVALID_EMAIL":
            return "Please enter a valid email address."
        case "TOO_MANY_ATTEMPTS_TRY_LATER":
            return "Too many attempts. Please try again later."
        default:
            return "Registration failed. Please check your information and try again."
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

extension Register {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
