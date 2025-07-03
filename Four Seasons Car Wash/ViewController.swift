//
//  ViewController.swift
//  Four Seasons Car Wash
//
//  Created by Paul Di Domenico on 2016-09-28.
//  Copyright © 2016 Tech1st Wash Systems. All rights reserved.
//

import UIKit
import Firebase
import MapKit
import CoreLocation
import SystemConfiguration

let service = "https://www.t1serv.com/fourseasons/cw.svc/"
//var onSite = true
var savedCard = "";
var hasSavedCard = false
let regularUser = 0
let fleetUser = 1
let fleetAdmin = 2
let owner = 3
let staff = 4
var userType = 0
var points = "0"

class ViewController: UIViewController {
    
    //var distance = 0.00
    var isLoggedin = false
    var email = ""
    var pass = ""
    var phoneNumber = ""
    var userId = ""
    let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50)) as UIActivityIndicatorView
    let alert = UIAlertController(title: "Please wait...", message: "This may take a moment", preferredStyle: .alert)
    var gotFreeCode = false
    var giveFreeCode = false
    //var locationManager = CLLocationManager()
    var net = false
    var menuVisible = false
    public static var theUrl = "https://tech1st.ca/app/privacy.aspx?wash=camera"
    
    @IBOutlet weak var infoIcon: UIImageView!
    @IBOutlet weak var navLogo: UIImageView!
    @IBOutlet var btnUseAutomatic: UIButton!
    @IBOutlet var lblAccountBalance: UILabel!
    @IBOutlet var btnPayPal: UIButton!
    @IBOutlet var btnUseCoinbay: UIButton!
    @IBOutlet var btnUseVacuum: UIButton!
    @IBOutlet var btnUseWashCode: UIButton!
    @IBOutlet var btnLogInOut: UIButton!
    @IBOutlet var btnForgotPass: UIButton!
    @IBOutlet var btnRegister: UIButton!
    @IBOutlet var myStackView: UIStackView!
    @IBOutlet weak var btnHome: UIButton!
    @IBOutlet weak var menu: UIBarButtonItem!
    @IBOutlet weak var leadingCon: NSLayoutConstraint!
    @IBOutlet weak var trailingCon: NSLayoutConstraint!
    @IBOutlet weak var lblReward: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //locationManager.delegate = self
        //locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //locationManager.requestWhenInUseAuthorization()
        //locationManager.startUpdatingLocation()
        
        UserDefaults.standard.set("", forKey: "balance")
        UserDefaults.standard.set(false, forKey: "paypal")
        UserDefaults.standard.set(true, forKey: "checkBalance")
        if (UserDefaults.standard.object(forKey: "userId") != nil)
        {
            userId = UserDefaults.standard.object(forKey: "userId") as! String
        }
        if (UserDefaults.standard.object(forKey: "loggedIn") != nil)
        {
            isLoggedin = UserDefaults.standard.object(forKey: "loggedIn") as! Bool
        }
        
        if (UserDefaults.standard.object(forKey: "fcm") == nil)
        {
            //print ("FCM token is nil")
            saveToken()
        }
        else {
            // print ("FCM token is GOOD")
        }
        
        Auth.auth().addStateDidChangeListener { auth, user in
            if user != nil {
                //print(user?.uid as Any)
                // print("User has signed in")
            } else {
                //  print("No user is signed in.")
            }
        }
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(self.imageTapped))
        infoIcon.addGestureRecognizer(tapGR)
        infoIcon.isUserInteractionEnabled = true
        
        overrideUserInterfaceStyle = .light
        btnHome.backgroundColor = UIColor.systemGray5
        btnHome.setTitleColor(UIColor.systemBlue, for:UIControl.State())
        navLogo.layer.cornerRadius = 10
        fixButtons()
        //locationDelay()
    }
    
    @objc func imageTapped(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            ViewController.theUrl = "https://tech1app.com/fourseasons/rewardpoints.aspx"
            self.performSegue(withIdentifier: "showWeb", sender: nil)
            closeItFast()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if (UserDefaults.standard.object(forKey: "loggedIn") != nil)
        {
            isLoggedin = UserDefaults.standard.object(forKey: "loggedIn") as! Bool
        }
        if (isLoggedin){
            btnUseAutomatic.isHidden = true
            let mySite = getSite()
            if (mySite == 3 || mySite == 4){
                btnUseAutomatic.isHidden = false
            }
        }
    }
    
    func checkNet() -> Bool {
        if !(ViewController.isConnectedToNetwork())
        {
            noInternet()
            net = false
            return false
        }
        else {
            net = true
            return true
        }
    }
    
    class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    
    func noInternet () {
        let alert = UIAlertController(title: "No Internet Connection", message:  "Please check your network connection and try again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    //    func locationDelay () {
    //        Timer.scheduledTimer(timeInterval: 12.0, target: self, selector: #selector(locationApproved), userInfo: nil, repeats: false)
    //    }
    //
    //    @objc func locationApproved () {
    //        if CLLocationManager.locationServicesEnabled() {
    //            switch(CLLocationManager.authorizationStatus()) {
    //            case .notDetermined, .restricted, .denied:
    //                let alert = UIAlertController(title: "Location Unavailable", message:  "Four Seasons Car Wash requires access to your location to use this app.", preferredStyle: .alert)
    //                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
    //                }))
    //                self.present(alert, animated: true, completion: nil)
    //            case .authorizedAlways, .authorizedWhenInUse:
    //                print("Access")
    //            @unknown default:
    //                break
    //            }
    //        }
    //    }
    
    func saveToken() {
        Messaging.messaging().token { token, error in
            if error != nil {
                //print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                //print("FCM registration token: \(token)")
                ViewController.fcmToken(token)
            }
        }
        Messaging.messaging().subscribe(toTopic: "all")
        //print("subscribed to topic all"
    }
    
    func checkUser() {
        if (Auth.auth().currentUser) != nil {
            // print("User has signed in")
        } else {
            //  print("No user is signed in.")
        }
    }
    
    func validPhone(_ number:String) -> Bool {
        if (number.isEmpty) {
            return true;
        }
        let newNumber = checkPhone(number)
        if (newNumber.count == 10) {
            phoneNumber = newNumber
            return true
        }
        else {
            phoneNumber = ""
            return false
        }
    }
    
    //    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    //        var mySite = 0
    //        if (UserDefaults.standard.object(forKey: "site") != nil)
    //        {
    //            mySite = UserDefaults.standard.object(forKey: "site") as! Int
    //        }
    //
    //        if (mySite == 0) {
    //            onSite = false
    //        }
    //        else if (mySite == 1) {
    //            let washLocation = CLLocation(latitude: 44.887286, longitude: -76.244504)
    //            let myLocation: CLLocation = locations[0]
    //            distance = myLocation.distance(from: washLocation) / 1000
    //            if (distance < 2) {
    //                onSite = true
    //                // print(onSite)
    //            }
    //            else {
    //                onSite = false
    //                // print(onSite)
    //            }
    //        }
    //        else if (mySite == 2) {
    //            let washLocation = CLLocation(latitude: 45.019511, longitude: -74.744216)
    //            let myLocation: CLLocation = locations[0]
    //            distance = myLocation.distance(from: washLocation) / 1000
    //            if (distance < 2) {
    //                onSite = true
    //                // print(onSite)
    //            }
    //            else {
    //                onSite = false
    //                // print(onSite)
    //            }
    //
    //        }
    //        else if (mySite == 3) {
    //            let washLocation = CLLocation(latitude: 45.431318, longitude: -76.335173)
    //            let myLocation: CLLocation = locations[0]
    //            distance = myLocation.distance(from: washLocation) / 1000
    //            if (distance < 2) {
    //                onSite = true
    //                // print(onSite)
    //            }
    //            else {
    //                onSite = false
    //                // print(onSite)
    //            }
    //        }
    //        else if (mySite == 4) {
    //            let washLocation = CLLocation(latitude: 45.143326, longitude: -76.132483)
    //            let myLocation: CLLocation = locations[0]
    //            distance = myLocation.distance(from: washLocation) / 1000
    //            if (distance < 2) {
    //                onSite = true
    //                // print(onSite)
    //            }
    //            else {
    //                onSite = false
    //                // print(onSite)
    //            }
    //        }
    //    }
    
    func checkPhone(_ number:String) -> String {
        let stringArray = number.components(
            separatedBy: CharacterSet.decimalDigits.inverted)
        let newNumber = stringArray.joined(separator: "")
        if (newNumber.count == 10) {
            return newNumber
        }
        else {
            self.view.makeToast(message: "Enter a valid phone number")
            return ""
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if(UserDefaults.standard.object(forKey: "checkBalance") as! Bool) {
            checkLogIn()
            UserDefaults.standard.set(false, forKey: "coinAdd")
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func gc(){
        let myUrl = URL(string: service + "gc")!
        var request = URLRequest(url:myUrl);
        request.httpMethod = "POST";
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let dictionary = ["u":userId]
        request.httpBody = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
        let task = URLSession.shared.dataTask(with: request, completionHandler: {
            data, response, error in
            if error != nil
            {
                return
            }
            
            do {
                savedCard = ""
                hasSavedCard = false
                let myJSON = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? NSDictionary
                if let parseJSON = myJSON {
                    let myResult = parseJSON["gcResult"] as? String
                    // print(myResult!)
                    if (myResult?.contains(","))! {
                        savedCard = myResult!
                        hasSavedCard = true
                    }
                }
            }
            catch {
                //print(error)
            }
        })
        task.resume()
    }
    
    @IBAction func payPalClicked(_ sender: Any) {
        if (getSite() != 0) {
            if (checkNet()) {
                if(isLoggedin){
                    UserDefaults.standard.set(true, forKey: "paypal")
                    self.performSegue(withIdentifier: "PayPal", sender: nil)
                }
                else {
                    view.makeToast(message: "Log In to make a purchase")
                }
            }
        }
    }
    
    @IBAction func btnUseAutomaticClicked(_ sender: Any) {
        if (getSite() == 3) {
            self.performSegue(withIdentifier: "showAutomatica", sender: nil)
        }
        else if (getSite() == 4) {
            self.performSegue(withIdentifier: "showAutomaticl", sender: nil)
        }
    }
    
    @objc func register() {
        if (checkNet()) {
            if (UserDefaults.standard.object(forKey: "freeCode") != nil)
            {
                gotFreeCode = UserDefaults.standard.object(forKey: "freeCode") as! Bool
            }
            
            if(gotFreeCode || !giveFreeCode) {
                let alert = UIAlertController(title: "Register", message: nil, preferredStyle: .alert)
                alert.addTextField(configurationHandler: { (textFieldEmail) -> Void in
                    textFieldEmail.placeholder = "email"
                })
                alert.addTextField(configurationHandler: { (textFieldPass) -> Void in
                    textFieldPass.placeholder = "password"
                    textFieldPass.isSecureTextEntry = true
                })
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
                    let textFieldE = alert.textFields![0] as UITextField
                    self.email = textFieldE.text!
                    let textFieldP = alert.textFields![1] as UITextField
                    self.pass = textFieldP.text!
                    
                    if (self.checkEmail(self.email) && self.checkPass(self.pass)) {
                        self.pleaseWait()
                        Auth.auth().createUser(withEmail: self.email, password: self.pass) { (user, error) in
                            if error != nil {
                                self.endWait()
                                self.handleFireBaseError(error! as NSError)
                            } else {
                                let uid = user!.user.uid
                                let myUrl = URL(string: service + "r")!
                                var request = URLRequest(url:myUrl);
                                request.httpMethod = "POST";
                                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                                var dictionary = [String: String]()
                                dictionary = ["i":uid,"e":self.email,"k":"q9183w"]
                                request.httpBody = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
                                let task = URLSession.shared.dataTask(with: request, completionHandler: {
                                    data, response, error in
                                    if error != nil
                                    {
                                        return
                                    }
                                    
                                    do {
                                        let myJSON = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? NSDictionary
                                        if let parseJSON = myJSON {
                                            let myResult = parseJSON["rResult"] as? String
                                            print(myResult!)
                                            if (myResult != "1")
                                            {
                                                self.removeUser()
                                                DispatchQueue.main.async(execute: { () -> Void in
                                                    self.endWait()
                                                })
                                            }
                                            else {
                                                UserDefaults.standard.set(true, forKey: "freeCode")
                                                DispatchQueue.main.async(execute: { () -> Void in
                                                    self.logInDelay()
                                                })
                                            }
                                        }
                                    }
                                    catch {
                                        self.endWait()
                                        self.removeUser()
                                    }
                                })
                                task.resume()
                            }
                        }
                    }
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel,handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            else {
                let alert = UIAlertController(title: "Register", message: "Try our app for FREE! \nEnter your phone number and we will text you a free $4.00 wash code to use in the coin bays. You may register without a phone number if you prefer.", preferredStyle: .alert)
                alert.addTextField(configurationHandler: { (textFieldNumber) -> Void in
                    textFieldNumber.placeholder = "optional phone number"
                })
                alert.addTextField(configurationHandler: { (textFieldEmail) -> Void in
                    textFieldEmail.placeholder = "email"
                })
                alert.addTextField(configurationHandler: { (textFieldPass) -> Void in
                    textFieldPass.placeholder = "password"
                    textFieldPass.isSecureTextEntry = true
                })
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
                    let textFieldN = alert.textFields![0] as UITextField
                    let number = textFieldN.text!
                    let textFieldE = alert.textFields![1] as UITextField
                    self.email = textFieldE.text!
                    let textFieldP = alert.textFields![2] as UITextField
                    self.pass = textFieldP.text!
                    
                    if (self.checkEmail(self.email) && self.checkPass(self.pass) && self.validPhone(number)) {
                        self.pleaseWait()
                        Auth.auth().createUser(withEmail: self.email, password: self.pass) { (user, error) in
                            if error != nil {
                                self.endWait()
                                self.handleFireBaseError(error! as NSError)
                            } else {
                                let uid = user!.user.uid
                                //print("Successfully created user account with uid: \(uid)")
                                var location = 0
                                if (UserDefaults.standard.object(forKey: "site") != nil)
                                {
                                    location = UserDefaults.standard.object(forKey: "site") as! Int
                                }
                                let l = String(location)
                                let myUrl = URL(string: service + "r")!
                                var request = URLRequest(url:myUrl);
                                request.httpMethod = "POST";
                                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                                var dictionary = [String: String]()
                                if (self.phoneNumber.count == 10) {
                                    dictionary = ["i":uid,"e":self.email,"k":"q9183w","l":l,"p":self.phoneNumber]
                                }
                                else {
                                    dictionary = ["i":uid,"e":self.email,"k":"q9183w","l":l]
                                }
                                request.httpBody = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
                                let task = URLSession.shared.dataTask(with: request, completionHandler: {
                                    data, response, error in
                                    
                                    if error != nil
                                    {
                                        return
                                    }
                                    
                                    do {
                                        let myJSON = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? NSDictionary
                                        if let parseJSON = myJSON {
                                            let myResult = parseJSON["rResult"] as? String
                                            if (myResult != "1")
                                            {
                                                self.removeUser()
                                                DispatchQueue.main.async(execute: { () -> Void in
                                                    self.endWait()
                                                })
                                            }
                                            else {
                                                UserDefaults.standard.set(true, forKey: "freeCode")
                                                DispatchQueue.main.async(execute: { () -> Void in
                                                    self.logInDelay()
                                                })
                                            }
                                        }
                                    }
                                    catch {
                                        self.endWait()
                                        self.removeUser()
                                    }
                                })
                                task.resume()
                            }
                        }
                    }
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel,handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func btnLogInOutClicked(_ sender: Any) {
        savedCard = ""
        hasSavedCard = false
        if (getSite() != 0)
        {
            if (isLoggedin){
                UserDefaults.standard.set(false, forKey: "loggedIn")
                UserDefaults.standard.set("", forKey: "userId")
                view.makeToast(message: "You are now logged out")
                self.checkLogIn()
            }
            else{
                if (checkNet()) {
                    var mail = "email"
                    if (UserDefaults.standard.object(forKey: "email") != nil) {
                        mail = UserDefaults.standard.object(forKey: "email") as! String
                    }
                    let alert = UIAlertController(title: "Log In", message: nil, preferredStyle: .alert)
                    
                    alert.addTextField(configurationHandler: { (textFieldEmail) -> Void in
                        if (mail == "email") {
                            textFieldEmail.placeholder = mail
                        }
                        else {
                            textFieldEmail.text = mail
                        }
                        
                    })
                    
                    alert.addTextField(configurationHandler: { (textFieldPass) -> Void in
                        textFieldPass.placeholder = "password"
                        textFieldPass.isSecureTextEntry = true
                    })
                    
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
                        let textFieldE = alert.textFields![0] as UITextField
                        self.email = textFieldE.text!
                        let textFieldP = alert.textFields![1] as UITextField
                        self.pass = textFieldP.text!
                        if (self.checkEmail(self.email) && self.checkPass(self.pass))
                        {
                            self.logIn()
                        }
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel,handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func btnRegisterClicked(_ sender: Any) {
        if (getSite() != 0)
        {
            if (checkNet()) {
                if (UserDefaults.standard.object(forKey: "freeCode") != nil)
                {
                    gotFreeCode = UserDefaults.standard.object(forKey: "freeCode") as! Bool
                }
                if (gotFreeCode) {
                    register()
                }
                else {
                    pleaseWait()
                    let myUrl = URL(string: service + "f")!
                    var request = URLRequest(url:myUrl);
                    request.httpMethod = "POST";
                    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                    let dictionary = [String: String]()
                    request.httpBody = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
                    let task = URLSession.shared.dataTask(with: request, completionHandler: {
                        data, response, error in
                        
                        if error != nil
                        {
                            return
                        }
                        
                        do {
                            let myJSON = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? NSDictionary
                            if let parseJSON = myJSON {
                                let myResult = parseJSON["fResult"] as? String
                                print(myResult!)
                                if (myResult != "1")
                                {
                                    self.giveFreeCode = false
                                    DispatchQueue.main.async(execute: { () -> Void in
                                        self.endWait()
                                        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.register), userInfo: nil, repeats: false)
                                        
                                    })
                                }
                                else {
                                    self.giveFreeCode = true
                                    DispatchQueue.main.async(execute: { () -> Void in
                                        self.endWait()
                                        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.register), userInfo: nil, repeats: false)
                                    })
                                }
                            }
                        }
                        catch {
                            self.endWait()
                            Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.register), userInfo: nil, repeats: false)                    }
                    })
                    task.resume()
                }
            }
        }
    }
    
    @IBAction func btnForgotPassClicked(_ sender: Any) {
        if (getSite() != 0)
        {
            if (checkNet()) {
                if (UserDefaults.standard.object(forKey: "email") != nil) {
                    email = UserDefaults.standard.object(forKey: "email") as! String
                }
                else {
                    email = "email"
                }
                
                let alert = UIAlertController(title: "Reset Password", message: "Enter email address", preferredStyle: .alert)
                
                alert.addTextField(configurationHandler: { (textFieldEmail) -> Void in
                    if (self.email != "email"){
                        textFieldEmail.text = self.email
                    }
                    else {
                        textFieldEmail.placeholder = "email"
                    }
                })
                
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
                    let textFieldE = alert.textFields![0] as UITextField
                    self.email = textFieldE.text!
                    if (self.checkEmail(self.email))
                    {  Auth.auth().sendPasswordReset(withEmail: self.email) { error in
                        if error != nil {
                            self.handleFireBaseError(error! as NSError)
                        } else {
                            self.showIt(titl: "Success", msg: "A link to reset your password has been sent.")
                            //self.view.makeToast(message: )
                        }
                    }
                    }
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel,handler: nil))
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func logInDelay() {
        Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(endWait), userInfo: nil, repeats: false)
        Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(logIn), userInfo: nil, repeats: false)
    }
    
    @objc func logIn() {
        view.makeToast(message: "Logging In")
        Auth.auth().signIn(withEmail: self.email, password: self.pass) { (user, error) in
            if error != nil {
                print(error!)
                self.handleFireBaseError(error! as NSError)
            } else {
                self.userId = user!.user.uid
                UserDefaults.standard.set(user!.user.uid, forKey: "userId")
                UserDefaults.standard.set(true, forKey: "loggedIn")
                UserDefaults.standard.set(self.email, forKey: "email")
                self.saveToken()
                self.checkLogIn()
            }
        }
    }
    
    func checkEmail(_ testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        if (emailTest.evaluate(with: testStr))
        {
            return true
        }
        else
        {
            self.view.makeToast(message: "Incorrect email address")
            return false
        }
    }
    
    func checkPass(_ testStr:String) -> Bool {
        if (testStr.count > 5 && testStr.count < 17)
        {
            return true
        }
        else
        {
            view.makeToast(message: "Password length must be between 6 and 16 characters")
            return false
        }
    }
    
    func checkLogIn() {
        if (UserDefaults.standard.object(forKey: "loggedIn") != nil)
        {
            isLoggedin = UserDefaults.standard.object(forKey: "loggedIn") as! Bool
        }
        if (isLoggedin) {
            getBalance()
            btnLogInOut.setTitle("Log Out", for: UIControl.State())
            btnRegister.isHidden = true
            btnForgotPass.isHidden = true
            btnUseVacuum.isHidden = false
            btnUseCoinbay.isHidden = false
            let mySite = getSite()
            if (mySite == 3 || mySite == 4){
                btnUseAutomatic.isHidden = false
            }
            else {
                btnUseAutomatic.isHidden = true
            }
            lblAccountBalance.isHidden = false
            lblReward.isHidden = false
            infoIcon.isHidden = false
            myStackView.spacing = 25
        }
        else {
            btnLogInOut.setTitle("Log In", for: UIControl.State())
            btnRegister.isHidden = false
            btnForgotPass.isHidden = false
            btnUseVacuum.isHidden = true
            btnUseCoinbay.isHidden = true
            btnUseAutomatic.isHidden = true
            lblAccountBalance.isHidden = true
            lblReward.isHidden = true
            infoIcon.isHidden = true
            myStackView.spacing = 25
            try! Auth.auth().signOut()
        }
        Messaging.messaging().subscribe(toTopic: "all")
    }
    
    func fixButtons () {
        ViewController.fixButton(btnUseCoinbay)
        ViewController.fixButton(btnUseVacuum)
        ViewController.fixButton(btnUseAutomatic)
        ViewController.fixButton(btnUseWashCode)
        ViewController.fixButton(btnLogInOut)
        ViewController.fixButton(btnRegister)
        ViewController.fixButton(btnForgotPass)
        ViewController.fixButton(btnPayPal)
    }
    
    @IBAction func navMenuClicked(_ sender: AnyObject) {
        if !menuVisible {
            leadingCon.constant = 270
            trailingCon.constant = -270
            menuVisible = true
            menu.title = "  X  "
        } else {
            leadingCon.constant = 0
            trailingCon.constant = 0
            menuVisible = false
            menu.title = "Menu"
        }
        
        UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
        }) { (animationComplete) in
        }
    }
    
    @IBAction func btnWashCodeClicked(_ sender: Any) {
        if(checkNet()){
            if (getSite() != 0) {
                self.performSegue(withIdentifier: "WashCode", sender: nil)
            }
        }
    }
    
    @IBAction func btnUseCoinBaysClicked(_ sender: Any) {
        if(checkNet()){
            let mySite = getSite()
            if (mySite == 1) {
                self.performSegue(withIdentifier: "UseCoinBay", sender: nil)
            }
            else if (mySite == 2) {
                self.performSegue(withIdentifier: "UseCoinBay2", sender: nil)
            }
            else if (mySite == 3) {
                self.performSegue(withIdentifier: "UseCoinBay3", sender: nil)
            }
            else if (mySite == 4) {
                self.performSegue(withIdentifier: "UseCoinBay4", sender: nil)
            }
        }
    }
    
    @IBAction func btnUseVacuumClicked(_ sender: Any) {
        if(checkNet()){
            let mySite = getSite()
            if (mySite == 1) {
                self.performSegue(withIdentifier: "UseVacuum", sender: nil)
            }
            else if (mySite == 2) {
                self.performSegue(withIdentifier: "UseVacuum2", sender: nil)
            }
            else if (mySite == 3) {
                self.performSegue(withIdentifier: "UseVacuum3", sender: nil)
            }
            else if (mySite == 4) {
                self.performSegue(withIdentifier: "UseVacuum4", sender: nil)
            }
        }
    }
    
    static func fixButton (_ button: UIButton) {
        button.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping;
        button.titleLabel?.textAlignment = NSTextAlignment.center
        button.setTitleColor(UIColor.white, for:UIControl.State())
        button.titleLabel!.font =  UIFont.boldSystemFont(ofSize: 18)
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1.0
        button.layer.backgroundColor = UIColor.lightGray.cgColor
        button.layer.borderColor = UIColor.blue.cgColor
    }
    
    func closeItFast() {
        leadingCon.constant = 0
        trailingCon.constant = 0
        menuVisible = false
        menu.title = "Menu"
    }
    
    @IBAction func btnMyAccountClicked(_ sender: Any) {
        if (UserDefaults.standard.object(forKey: "loggedIn") != nil)
        {
            if(UserDefaults.standard.object(forKey: "loggedIn") as! Bool)
            {
                performSegue(withIdentifier: "MyAccount", sender: nil)
                closeItFast()
            }
            else {
                view.makeToast(message: "Log in to view your account details")
            }
        }
        else {
            view.makeToast(message: "Log in to view your account details")
        }
    }
    
    @IBAction func btnContactClicked(_ sender: Any) {
        ViewController.theUrl = "https://tech1app.com/fourseasons/contact.aspx?pass=Contact"
        self.performSegue(withIdentifier: "showWeb", sender: nil)
        closeItFast()
    }
    
    @IBAction func btnPrivacyPolicyClicked(_ sender: Any) {
        ViewController.theUrl = "https://tech1st.ca/app/privacy.aspx?wash=camera"
        self.performSegue(withIdentifier: "showWeb", sender: nil)
        closeItFast()
    }
    
    @IBAction func btnRedeemGiftCardClicked(_ sender: Any) {
        if (UserDefaults.standard.object(forKey: "loggedIn") != nil)
        {
            if(UserDefaults.standard.object(forKey: "loggedIn") as! Bool)
            {
                var id = ""
                if (UserDefaults.standard.object(forKey: "userId") != nil)
                {
                    id = UserDefaults.standard.object(forKey: "userId") as! String
                }
                UserDefaults.standard.set(true, forKey: "checkBalance")
                ViewController.theUrl = "https://tech1app.com/fourseasons/gcredeem.aspx?userID=" + id
                self.performSegue(withIdentifier: "showWeb", sender: nil)
                closeItFast()
            }
            else {
                view.makeToast(message: "Log in to redeem a gift card")
            }
        }
        else {
            view.makeToast(message: "Log in to redeem a gift card")
        }
    }
    
    @IBAction func btnSelectLocationClicked(_ sender: Any) {
        self.performSegue(withIdentifier: "showLocation", sender: nil)
        closeItFast()
    }
    
    //    @IBAction func btnTutorialsClicked(_ sender: Any) {
    //        ViewController.theUrl = "https://tech1app.com/fourseasons/itutorials.aspx?pass=coolpass"
    //        self.performSegue(withIdentifier: "showWeb", sender: nil)
    //        closeItFast()
    //    }
    
    @IBAction func btnCurrentPromotionsClicked(_ sender: Any) {
        ViewController.theUrl = "https://tech1app.com/fourseasons/promoboard.aspx?pass=coolpass"
        self.performSegue(withIdentifier: "showWeb", sender: nil)
        closeItFast()
    }
    
    @objc func balanceDelayedAction(){
        let myUrl = URL(string: service + "butp")!
        var request = URLRequest(url:myUrl);
        request.httpMethod = "POST";
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let dictionary = ["i":userId, "k":"eCCz3918mNme"]
        request.httpBody = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
        let task = URLSession.shared.dataTask(with: request, completionHandler: {
            data, response, error in
            if error != nil
            {
                //print("error=\(error)")
                self.endWait()
                return
            }
            
            do {
                let myJSON = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? NSDictionary
                if let parseJSON = myJSON {
                    var b = "";
                    let myResult = parseJSON["butpResult"] as? String
                    //print(myResult!)
                    if ((myResult?.contains(",")) != nil){
                        let bArr = myResult!.components(separatedBy: ",")
                        b = bArr[0]
                        userType = Int(bArr[1])!
                        points = (bArr[2])
                    }
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.lblAccountBalance.text = "Account Balance " + b
                        self.lblReward.text = points + " Reward Points"
                        self.endWait()
                        UserDefaults.standard.set(b, forKey: "balance")
                        UserDefaults.standard.set(false, forKey: "checkBalance")
                        //self.checkRewards()
                        self.gc()
                    })
                }
            }
            catch {
                //print(error)
            }
        })
        task.resume()
    }
    
    static func fcmToken(_ token:String){
        if (token.count > 5 && isConnectedToNetwork()) {
            var id = ""
            if (UserDefaults.standard.object(forKey: "userId") != nil)
            {
                id = UserDefaults.standard.object(forKey: "userId") as! String
            }
            let myUrl = URL(string: service + "t")!
            var request = URLRequest(url:myUrl);
            request.httpMethod = "POST";
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let dictionary = ["i":id,"t":token,"k":"2Pr6Tg3XlPq"]
            //print (id + " " + token)
            request.httpBody = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
            let task = URLSession.shared.dataTask(with: request, completionHandler: {
                data, response, error in
                if error != nil
                {
                    return
                }
                
                do {
                    let myJSON = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? NSDictionary
                    if let parseJSON = myJSON {
                        let myResult = parseJSON["tResult"] as? String
                        print("tResult is " + myResult!)
                        if (myResult == "1") {
                            UserDefaults.standard.set(token, forKey: "fcm")
                            //print("key saved to phone")
                        }
                    }
                }
                catch {
                    //print(error)
                }
            })
            task.resume()
        }
    }
    
    func getBalance () {
        if (checkNet()) {
            if(isLoggedin) {
                pleaseWait()
                let didPay = UserDefaults.standard.object(forKey: "paypal") as! Bool
                if (didPay) {
                    alert.message = "\nChecking for a recent PayPal purchase. \n\nThis will take a moment."
                    UserDefaults.standard.set(false, forKey: "paypal")
                    Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(balanceDelayedAction), userInfo: nil, repeats: false)
                }
                else {
                    alert.message = "This may take a moment"
                    Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(balanceDelayedAction), userInfo: nil, repeats: false)
                }
                
            }
        }
    }
    
    func pleaseWait() {
        alert.view.tintColor = UIColor.black
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.large
        loadingIndicator.color = UIColor.red
        loadingIndicator.startAnimating();
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
    }
    
    @objc func endWait() {
        self.dismiss(animated: false, completion: nil)
    }
    
    @objc func removeUserDelay() {
        let user = Auth.auth().currentUser
        user?.delete { error in
            if error != nil {
                
            } else {
                
            }
        }
    }
    
    func removeUser () {
        Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(removeUserDelay), userInfo: nil, repeats: false)
    }
    
    func showIt(titl:String, msg:String) {
        let dialogMessage = UIAlertController(title: titl, message: msg, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            
        })
        dialogMessage.addAction(ok)
        self.present(dialogMessage, animated: true, completion: nil)
    }
    
    func handleFireBaseError (_ error:NSError) {
        print(error.localizedDescription)
        if (error.localizedDescription.contains("The password is invalid")) {
            self.showIt(titl: "Oops...", msg: "The password is invalid.  Please try again.")
        }
        else if (error.localizedDescription.contains("There is no user record corresponding to this identifier")) {
            self.showIt(titl: "Oops...", msg: "Email address not found.  Please try again.")
        }
        else if (error.localizedDescription.contains("The email address is already in use by")) {
            self.showIt(titl: "Oops...", msg: "This email address is already in use.")
        }
        else {
            self.showIt(titl: "Oops...", msg: "Something went wrong.  Please try again.")
        }
    }
    
}

extension UIViewController {
    
    func getCardType(ct:String) -> String {
        var cardType = ct
        if (cardType.uppercased().starts(with: "V")){
            cardType = "Visa "
        }
        else if (cardType.uppercased().starts(with: "M")){
            cardType = "MasterCard "
        }
        else {
            cardType = "Card "
        }
        return cardType
    }
    
    func getSite () -> Int {
        
        var returnSite = 0
        
        if (UserDefaults.standard.object(forKey: "site") != nil)
        {
            returnSite = UserDefaults.standard.object(forKey: "site") as! Int
        }
        if (returnSite == 0)
        {
            self.performSegue(withIdentifier: "showLocation", sender: nil)
        }
        return returnSite
    }
    
    func connecting() {
        self.view.makeToast(message: "\nOne moment please...\n")
    }
    
    @objc func thanks () {
        self.performSegue(withIdentifier: "ThankYou", sender: nil)
    }
    
    func back1() {
        _ = navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func automaticQRprep () {
        self.performSegue(withIdentifier: "showQRprep", sender: nil)
    }
    
    @objc func washError () {
        self.performSegue(withIdentifier: "showWashError", sender: nil)
    }
    
    @objc func washBusy () {
        self.performSegue(withIdentifier: "showWashBusy", sender: nil)
    }
    
    @objc func goHome () {
        self.performSegue(withIdentifier: "showHome", sender: nil)
    }
    
    func startRequest(type:String, deviceChosen:String, amountChosen:String, code:String, equip:String) {
        
        if(ViewController.isConnectedToNetwork()) {
            //if (onSite) {
            var myResult = ""
            var id = ""
            var dictionary = [String: String]()
            if (UserDefaults.standard.object(forKey: "userId") != nil)
            {
                id = UserDefaults.standard.object(forKey: "userId") as! String
            }
            
            let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50)) as UIActivityIndicatorView
            let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
            alert.view.tintColor = UIColor.black
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = UIActivityIndicatorView.Style.large
            loadingIndicator.color = UIColor.red
            loadingIndicator.startAnimating();
            alert.view.addSubview(loadingIndicator)
            present(alert, animated: true, completion: nil)
            var myUrl = URL(string: service + "s")!
            
            if (type == "wca") {
                myUrl = URL(string: service + "wca")!
                dictionary = ["k":"W!!dl8966!Qz","wc":code]
                
            }
            else if (type == "wc") {
                myUrl = URL(string: service + "wc")!
                dictionary = ["k":"W!!dl8966!Qz","wc":code,"d":deviceChosen,"e":equip]
                
            }
            else {
                dictionary = ["i":id,"a":amountChosen, "k":"8qlpCCz3Wxp4@4djka!!","d":deviceChosen]
            }
            
            var request = URLRequest(url:myUrl);
            request.httpMethod = "POST";
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
            
            let task = URLSession.shared.dataTask(with: request, completionHandler: {
                data, response, error in
                
                if error != nil
                {
                    return
                }
                
                do {
                    let myJSON = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? NSDictionary
                    
                    if let parseJSON = myJSON {
                        if (type == "wca") {
                            myResult = (parseJSON["wcaResult"] as? String)!
                        }
                        else if (type == "t") {
                            myResult = (parseJSON["sResult"] as? String)!
                        }
                        else {
                            myResult = (parseJSON["wcResult"] as? String)!
                        }
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.dismiss(animated: false, completion: nil)
                            
                            if (myResult == "1") {
                                if (type == "wca") {
                                    UserDefaults.standard.set(code, forKey: "washCode")
                                    UserDefaults.standard.set(true, forKey: "washCodeChosen")
                                    Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.automaticQRprep), userInfo: nil, repeats: false)
                                }
                                else if (type == "wc") {
                                    Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.thanks), userInfo: nil, repeats: false)
                                }
                                else {
                                    if (deviceChosen.contains("BAY"))
                                    {
                                        self.performSegue(withIdentifier: "coinbayThankYou", sender: nil)
                                        
                                    }
                                    else {
                                        self.performSegue(withIdentifier: "ThankYou", sender: nil)
                                    }
                                }
                            }
                            else if (myResult == "0") {
                                if (type == "wc" || type == "wca") {
                                    self.view.makeToast(message: "Invalid wash code")
                                }
                                else {
                                    self.view.makeToast(message: "Cannot complete transaction \n Please try again")
                                }
                            }
                            else if (myResult == "-1") {
                                if (deviceChosen.contains("WASH")) {
                                    Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.washError), userInfo: nil, repeats: false)
                                }
                                else {
                                    self.view.makeToast(message: "Error \n Cannot complete transaction \n Please try again")
                                }
                            }
                            else if (myResult == "-2") {
                                self.view.makeToast(message: "Wash code already used")
                            }
                            else if (myResult == "-3") {
                                self.view.makeToast(message: "Wash code valid for vacuums only")
                            }
                            else if (myResult == "-4") {
                                self.view.makeToast(message: "Wash code valid for coin bays only")
                            }
                            else if (myResult == "-6") {
                                self.view.makeToast(message: "This wash code cannot be used for the touchless automatic wash")
                            }
                            else if (myResult == "-9") {
                                self.view.makeToast(message: "Wash code is expired")
                            }
                            else if (myResult == "-10") {
                                self.view.makeToast(message: "Wash code valid for automatic touchless wash only")
                            }
                            else if (myResult == "-12") {
                                Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.washBusy), userInfo: nil, repeats: false)
                            }
                        })
                    }
                }
                catch {
                    //print(error)
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.dismiss(animated: false, completion: nil)
                    })
                }
            })
            task.resume()
            //}
            //            else {
            //                let alert = UIAlertController(title: "Safety First", message: "You must be at the car wash to start any equipment.", preferredStyle: .alert)
            //                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
            //                }))
            //                self.present(alert, animated: true, completion: nil)
            //            }
        }
        
        else {
            let alert = UIAlertController(title: "No Internet Connection", message:  "Please check your network connection and try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func startRequestWithPurchase(deviceChosen:String, amountChosen:String, equip:String, purchaseAmount:String) {
        if(ViewController.isConnectedToNetwork()) {
            //if (onSite) {
            //print(deviceChosen + " " + amountChosen + " " + equip + " " + purchaseAmount)
            var myResult = ""
            var id = ""
            var dictionary = [String: String]()
            if (UserDefaults.standard.object(forKey: "userId") != nil)
            {
                id = UserDefaults.standard.object(forKey: "userId") as! String
            }
            
            let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50)) as UIActivityIndicatorView
            let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
            alert.view.tintColor = UIColor.black
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = UIActivityIndicatorView.Style.large
            loadingIndicator.color = UIColor.red
            loadingIndicator.startAnimating();
            alert.view.addSubview(loadingIndicator)
            present(alert, animated: true, completion: nil)
            let myUrl = URL(string: service + "impwv")!
            
            dictionary = ["i":id,"a":amountChosen, "k":"8qlpCCz3Wxp4@4djka!!","d":deviceChosen, "pa":purchaseAmount]
            
            var request = URLRequest(url:myUrl);
            request.httpMethod = "POST";
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
            let task = URLSession.shared.dataTask(with: request, completionHandler: {
                data, response, error in
                
                if error != nil
                {
                    // print("error=\(error)")
                    return
                }
                
                do {
                    let myJSON = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? NSDictionary
                    
                    if let parseJSON = myJSON {
                        myResult = (parseJSON["impwvResult"] as? String)!
                        
                        //print(myResult)
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.dismiss(animated: false, completion: nil)
                            
                            if (myResult == "1") {
                                self.performSegue(withIdentifier: "ThankYou", sender: nil)
                            }
                            else if (myResult == "0") {
                                self.view.makeToast(message: "Cannot complete transaction \n Please try again")
                            }
                            else if (myResult == "-1") {
                                self.view.makeToast(message: "Error \n Cannot complete transaction \n Please try again")
                            }
                        })
                    }
                }
                catch {
                    //print(error)
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.dismiss(animated: false, completion: nil)
                    })
                }
            })
            task.resume()
        }
        //            else {
        //                let alert = UIAlertController(title: "Safety First", message: "You must be at the car wash to start any equipment. Please make sure you have set your current location correctly.", preferredStyle: .alert)
        //                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
        //                }))
        //                self.present(alert, animated: true, completion: nil)
        //            }
        //      }
        else {
            let alert = UIAlertController(title: "No Internet Connection", message:  "Please check your network connection and try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func startRequestForWashPurchase(purchaseAmount:String) {
        if(ViewController.isConnectedToNetwork()) {
            //if (onSite) {
            //print(deviceChosen + " " + amountChosen + " " + equip + " " + purchaseAmount)
            var myResult = ""
            var id = ""
            var dictionary = [String: String]()
            if (UserDefaults.standard.object(forKey: "userId") != nil)
            {
                id = UserDefaults.standard.object(forKey: "userId") as! String
            }
            
            let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50)) as UIActivityIndicatorView
            let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
            alert.view.tintColor = UIColor.black
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = UIActivityIndicatorView.Style.large
            loadingIndicator.color = UIColor.red
            loadingIndicator.startAnimating();
            alert.view.addSubview(loadingIndicator)
            present(alert, animated: true, completion: nil)
            let myUrl = URL(string: service + "impwvforwash")!
            
            dictionary = ["i":id,"pa":purchaseAmount]
            
            var request = URLRequest(url:myUrl);
            request.httpMethod = "POST";
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
            let task = URLSession.shared.dataTask(with: request, completionHandler: {
                data, response, error in
                
                if error != nil
                {
                    // print("error=\(error)")
                    return
                }
                
                do {
                    let myJSON = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? NSDictionary
                    
                    if let parseJSON = myJSON {
                        myResult = (parseJSON["impwvforwashResult"] as? String)!
                        
                        //print(myResult)
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.dismiss(animated: false, completion: nil)
                            
                            if (myResult == "Y") {
                                self.performSegue(withIdentifier: "showQRprep", sender: nil)
                            }
                            else if (myResult == "N") {
                                self.view.makeToast(message: "Cannot complete transaction \n Please try again")
                            }
                            else if (myResult == "-1") {
                                self.view.makeToast(message: "Error \n Cannot complete transaction \n Please try again")
                            }
                        })
                    }
                }
                catch {
                    //print(error)
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.dismiss(animated: false, completion: nil)
                    })
                }
            })
            task.resume()
        }
        // else {
        //     let alert = UIAlertController(title: "Safety First", message: "You must be at the car wash to start any equipment. Please make sure you have set your current location correctly.", preferredStyle: .alert)
        //     alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
        //     }))
        //     self.present(alert, animated: true, completion: nil)
        // }
        // }
        else {
            let alert = UIAlertController(title: "No Internet Connection", message:  "Please check your network connection and try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}
