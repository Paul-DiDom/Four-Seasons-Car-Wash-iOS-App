import UIKit
import Foundation

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
        else if (!isValidPhone(number: fixedPhoneNum)){
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
        
        registerUser("empty", firstName: firstNameText, lastName: lastNameText, email: emailText, password: passwordText, phoneNumber: fixedPhoneNum)
        
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
    
//    @IBAction func btnRegisterClicked(_ sender: Any) {
//        if (getSite() != 0)
//        {
//            if (checkNet()) {
//                if (UserDefaults.standard.object(forKey: "freeCode") != nil)
//                {
//                    gotFreeCode = UserDefaults.standard.object(forKey: "freeCode") as! Bool
//                }
//                if (gotFreeCode) {
//                    register()
//                }
//                else {
//                    pleaseWait()
//                    let myUrl = URL(string: service + "f")!
//                    var request = URLRequest(url:myUrl);
//                    request.httpMethod = "POST";
//                    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
//                    let dictionary = [String: String]()
//                    request.httpBody = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
//                    let task = URLSession.shared.dataTask(with: request, completionHandler: {
//                        data, response, error in
//                        
//                        if error != nil
//                        {
//                            return
//                        }
//                        
//                        do {
//                            let myJSON = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? NSDictionary
//                            if let parseJSON = myJSON {
//                                let myResult = parseJSON["fResult"] as? String
//                                print(myResult!)
//                                if (myResult != "1")
//                                {
//                                    self.giveFreeCode = false
//                                    DispatchQueue.main.async(execute: { () -> Void in
//                                        self.endWait()
//                                        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.register), userInfo: nil, repeats: false)
//                                        
//                                    })
//                                }
//                                else {
//                                    self.giveFreeCode = true
//                                    DispatchQueue.main.async(execute: { () -> Void in
//                                        self.endWait()
//                                        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.register), userInfo: nil, repeats: false)
//                                    })
//                                }
//                            }
//                        }
//                        catch {
//                            self.endWait()
//                            Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.register), userInfo: nil, repeats: false)                    }
//                    })
//                    task.resume()
//                }
//            }
//        }
//    }
    
}

extension Register {
   func textFieldShouldReturn(_ textField: UITextField) -> Bool {
      textField.resignFirstResponder()
   }
}
