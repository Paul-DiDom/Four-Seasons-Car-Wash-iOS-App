import UIKit
import Firebase
import WebKit

class myAccount: UIViewController , WKUIDelegate {
    

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet var btnChangePass: UIButton!
    @IBOutlet var emailText: UILabel!
    
    var email = "email"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        if (UserDefaults.standard.object(forKey: "email") != nil) {
            email = UserDefaults.standard.object(forKey: "email") as! String
            emailText.text = email;
        }
        var userid = ""
        if (UserDefaults.standard.object(forKey: "userId") != nil)
        {
            userid = UserDefaults.standard.object(forKey: "userId") as! String
        }
        ViewController.fixButton(btnChangePass)
        
        if (userid != "") {
            let url = URL (string:"https://tech1app.com/fourseasons/Transactions.aspx?userID=" + userid)
            let request = URLRequest(url: url!)
            webView.load(request)
        }
        UserDefaults.standard.set(true, forKey: "checkBalance")
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        view.makeToast(message: "Getting Transactions \nPlease Wait...")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func checkPass(_ testStr:String) -> Bool {
        if (testStr.count > 5 && testStr.count < 17)
        {
            return true
        }
        else
        {
            self.showIt(titl: "Oops...", msg: "Password length must be between 6 and 16 characters.")
            ///view.makeToast(message: "Password length must be between 6 and 16 characters")
            return false
        }
    }

    @IBAction func btnChangePassClicked(_ sender: AnyObject) {
        
        var newPass = "new"
        var confirmPass = "confirm"
        let alert = UIAlertController(title: "Change Password", message: nil, preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { (textFieldNewPass) -> Void in
            textFieldNewPass.placeholder = "new password"
            textFieldNewPass.isSecureTextEntry = true

        })
        
        alert.addTextField(configurationHandler: { (textFieldConfirmPass) -> Void in
            textFieldConfirmPass.placeholder = "confirm password"
            textFieldConfirmPass.isSecureTextEntry = true
        })
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
           
            let textFieldNew = alert.textFields![0] as UITextField
            newPass = textFieldNew.text!
            let textFieldConfirm = alert.textFields![1] as UITextField
            confirmPass = textFieldConfirm.text!
            
            if (self.checkPass(newPass))
            {
                if (newPass == confirmPass) {
                    let user = Auth.auth().currentUser
                    user?.updatePassword(to: newPass) { error in
                        if error != nil {
                            self.showIt(titl: "Error", msg: "You have not logged in recently.  You must log out and then log in to before you can your password.")
                        } else {
                            self.showIt(titl: "Success", msg: "Your password has been updated.")
                        }
                    }
                    
                }
                else {
                    self.showIt(titl: "Oops...", msg: "The new password and confirm password do not match.  Please try again.")
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel,handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func showIt(titl:String, msg:String) {
        let dialogMessage = UIAlertController(title: titl, message: msg, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
           
         })
        dialogMessage.addAction(ok)
        self.present(dialogMessage, animated: true, completion: nil)
    }
    
    
}
