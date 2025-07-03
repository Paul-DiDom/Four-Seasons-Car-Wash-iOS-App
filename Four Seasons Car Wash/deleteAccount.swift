/Users/pauldidomenico/Desktop/ScottStreet-Car-Wash-iOS/Scott Street Car Wash/LoginViewController.swiftimport UIKit
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
        print(userEmail)
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
        if (isLoggedIn){
            let passText = txtPass.text!
            if (passText.count < 6 || passText.count > 16)
            {
                showIt(title: "", msg: "Valid password must be between 6 and 16 characters")
                return
            }
            
            Auth.auth().signIn(withEmail: userEmail, password: passText) {authResult, error in
                if ((error) != nil){
                    //print (error as Any)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.handleFireBaseError(error: error! as NSError)
                    }
                }
                
                else {
                    var token = "";
                    if (authResult?.user != nil) {
                        userId = (authResult?.user.uid)!
                        // print("Log in successful")
                        // print(userId)
                        
                        let user = Auth.auth().currentUser
                        user?.getIDTokenResult(completion: { (authresult, error) in
                            //print("CurrentUser Keys", authresult!.claims.keys)
                            token = authresult?.token ?? ""
                            
                            if (token != ""){
                                var dictionary = [String: String]()
                                let myUrl = URL(string: web_url + "remove")!
                                //print (myUrl)
                                dictionary = ["k":APP_KEY, "c":APP_CLIENT, "s":SITE, "plat":PLATFORM, "t":token, "u":userId]
                                //print (dictionary)
                                var request = URLRequest(url:myUrl);
                                request.httpMethod = "POST";
                                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                                request.httpBody = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
                                let task = URLSession.shared.dataTask(with: request, completionHandler: {
                                    data, response, error in
                                    
                                    if error != nil
                                    {
                                        //print("in the error")
                                        //print("error=\(String(describing: error))")
                                        self.showIt(title: "", msg: "An error occurred.  Please try again.")
                                        return
                                    }
                                    do {
                                        print(String(data: data!, encoding: .utf8)!)
                                        var theData = String(data: data!, encoding: .utf8)!
                                        var newData = Data(theData.utf8)
                                        
                                        let json = try? JSONSerialization.jsonObject(with: data!, options: [])
                                        var goodResult = false
                                        var error = ""
                                        if let dictionary = json as? [String: Any] {
                                            
                                            if let success = dictionary["success"] as? Bool {
                                                if (success == true){
                                                    goodResult = true
                                                }
                                                else {
                                                    if (success == false){
                                                        goodResult = false
                                                    }
                                                }
                                            }
                                            
                                            if (goodResult){
                                                UserDefaults.standard.set(false, forKey: "loggedIn")
                                                UserDefaults.standard.set("", forKey: "userId")
                                                UserDefaults.standard.set("", forKey: "userEmail")
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                                    self.performSegue(withIdentifier: "login", sender: self)
                                                }
                                            }
                                            else{
                                                self.showIt(title: "", msg: "An error occurred.  Please try again.")
                                            }
                                        }
                                    }
                                    
                                })
                                task.resume()
                            }
                            
                            else{
                                //print("token is " +  token)
                                self.showIt(title: "", msg: "An error occurred.  Please try again.")
                            }
                            
                        })
                        
                        
                    }
                    
                    else {
                        self.showIt(title: "", msg: "An error occurred.  Please try again.")
                    }
                }
                
                
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
