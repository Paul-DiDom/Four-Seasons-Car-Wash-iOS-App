import UIKit
import FirebaseAuth

class LoginViewController: UIViewController, UITextFieldDelegate {
        
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        self.navigationItem.setHidesBackButton(true, animated: true)
        
        email.delegate = self
        password.delegate = self
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if (wasLoggedIn == newOpen){
                
            }
            else if (wasLoggedIn == justLoggedOut){
                self.showIt(title: "Success", msg: "You are now logged out.")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setGradientBackground()
        super.viewWillAppear(animated)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @IBAction func btnSignInPressed(_ sender: Any) {
        if (isValidEmail(email.text ?? "")){
            if (password.text?.count ?? 0 > 5 && password.text?.count ?? 0 < 17){
                
            }
            else{
                self.showIt(title: "", msg: "Password must be between 6 and 16 characters in length")
                return
            }
        }
        else {
            self.showIt(title: "", msg: "Please enter a valid email address")
            return
        }
        
        logIn(email: email.text ?? "", password: password.text ?? "")
    }
    
    @IBAction func btnForgotPasswordPressed(_ sender: Any) {
        if (isConnectedToNetwork()) {
            let alert = UIAlertController(title: "Reset Password", message: "Enter email address", preferredStyle: .alert)
            
            alert.addTextField(configurationHandler: { (textFieldEmail) -> Void in
                if (userEmail != "email"){
                    textFieldEmail.text = userEmail
                }
                else {
                    textFieldEmail.placeholder = "email"
                }
            })
            
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
                let textFieldE = alert.textFields![0] as UITextField
                userEmail = textFieldE.text!
                self.resetPassword(email: userEmail)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel,handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func btnAsGuestClicked(_ sender: Any) {
        self.performSegue(withIdentifier: "home", sender: self)
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
    
    func isValidPhone(number:String) -> Bool {
        if (number.isEmpty || number.count == 0) {
            return true
        }
        else if (number.count > 9 && number.count < 13) {
            return true
        }
        return false
    }
    
    func isConnectedToNetwork() -> Bool {
        if (netConnected){
            return netConnected
        }
        showIt(title:"No Internet Connection", msg: "Please check your network connection and try again.")
        return netConnected
    }
    
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
      textField.resignFirstResponder()
   }
}
