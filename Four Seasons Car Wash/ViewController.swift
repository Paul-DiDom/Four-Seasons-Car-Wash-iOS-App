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
var savedCard = "";
var hasSavedCard = false
let regularUser = 0
// let fleetUser = 1
// let fleetAdmin = 2
// let owner = 3
// let staff = 4
var userType = 0
var points = "0"
let newOpen = 0
let justLoggedOut = 1
let alreadyLoggedOut = 2
var wasLoggedIn = newOpen
var checkBalance = true
var moveToLoginOnceCompleted = false;
// var onSite = true
// var distance = 0.00
var netConnected = false
var userId = ""
var userEmail = ""
var isLoggedIn = false
let navyBlue = UIColor(red: 0x30/255.0, green: 0x3F/255.0, blue: 0x9F/255.0, alpha: 1.0)
let myGrey = UIColor(red: 0.933, green: 0.933, blue: 0.933, alpha: 1.0)
var saveTokenOnce = false
let myDebug = true //false

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var email = ""
    var pass = ""
    var phoneNumber = ""
    var userId = ""
    let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50)) as UIActivityIndicatorView
    let alert = UIAlertController(title: "Please wait...", message: "This may take a moment", preferredStyle: .alert)
    var gotFreeCode = false
    var giveFreeCode = false
    //var locationManager = CLLocationManager()
    var menuVisible = false
    public static var theUrl = "https://tech1st.ca/app/privacy.aspx?wash=camera"
    
    @IBOutlet weak var infoIcon: UIImageView!
    @IBOutlet weak var navLogo: UIImageView!
    @IBOutlet var lblAccountBalance: UILabel!
    @IBOutlet weak var btnHome: UIButton!
    @IBOutlet weak var btnMyAccount: UIButton!
    @IBOutlet weak var btnPrivacy: UIButton!
    @IBOutlet weak var btnCurrentPromos: UIButton!
    @IBOutlet weak var btnGiftCard: UIButton!
    @IBOutlet weak var btnSelectLocation: UIButton!
    @IBOutlet weak var btnAddGiftCard: UIButton!
    @IBOutlet weak var btnContactUs: UIButton!
    @IBOutlet weak var menu: UIBarButtonItem!
    @IBOutlet weak var leadingCon: NSLayoutConstraint!
    @IBOutlet weak var trailingCon: NSLayoutConstraint!
    @IBOutlet weak var lblReward: UILabel!
    @IBOutlet weak var homeIcon: UIImageView!
    @IBOutlet weak var UITableView: UITableView!
    
    var optionArray = ["Buy Now", "Use Touchless Automatic", "Use Wash Bay", "Use Vacuum", "Use Wash Code", "Log In / Sign Up"]
    var iconsArray = ["creditcard", "car", "drop", "car.top.door.front.left.open", "qrcode", "lock.open"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //locationManager.delegate = self
        //locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //locationManager.requestWhenInUseAuthorization()
        //locationManager.startUpdatingLocation()
        
        UserDefaults.standard.set("$0.00", forKey: "balance")
        UserDefaults.standard.set(false, forKey: "paypal")
        UserDefaults.standard.set(true, forKey: "checkBalance")
        if (UserDefaults.standard.object(forKey: "userId") != nil)
        {
            userId = UserDefaults.standard.object(forKey: "userId") as! String
        }
        if (UserDefaults.standard.object(forKey: "loggedIn") != nil)
        {
            isLoggedIn = UserDefaults.standard.object(forKey: "loggedIn") as! Bool
        }
        if (UserDefaults.standard.object(forKey: "userEmail") != nil)
        {
            userEmail = UserDefaults.standard.object(forKey: "userEmail") as! String
        }
        
        debugPrint("userEmail: " + userEmail)
        debugPrint("userId: " + userId)
        debugPrint("isLoggedIn: " + String(isLoggedIn))
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(self.imageTapped))
        infoIcon.addGestureRecognizer(tapGR)
        infoIcon.isUserInteractionEnabled = true
        
        overrideUserInterfaceStyle = .light
        navLogo.layer.cornerRadius = 10
        
        UITableView.delegate = self
        UITableView.dataSource = self
        
        // Fix table view styling
        UITableView.backgroundColor = UIColor.systemBackground  // White background
        UITableView.separatorStyle = .none  // Remove separator lines
        UITableView.showsVerticalScrollIndicator = false
        UITableView.showsHorizontalScrollIndicator = true
        UITableView.isScrollEnabled = true
        UITableView.contentInset = .zero
        UITableView.contentInsetAdjustmentBehavior = .never

        // menu.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: navyBlue], for: .normal)
        menu.setTitleTextAttributes([
            NSAttributedString.Key.foregroundColor: navyBlue,
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: UIFont.buttonFontSize)
        ], for: .normal)
        
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
        
        var logInOutButton = "Log In / Sign Up"
        if (isLoggedIn){
            logInOutButton = "Log Out"
        }
        
        let mySite = getSite()
        if mySite == 3 || mySite == 4 {
            optionArray = ["Buy Now", "Use Touchless Automatic", "Use Wash Bay", "Use Vacuum", "Use Wash Code", logInOutButton]
        } else {
            optionArray = ["Buy Now", "Use Wash Bay", "Use Vacuum", "Use Wash Code", logInOutButton]
        }
        UITableView.reloadData()
        
        btnHome.setImage(UIImage(systemName: "house"), for: .normal)
        btnMyAccount.setImage(UIImage(systemName: "person.circle"), for: .normal)
        btnSelectLocation.setImage(UIImage(systemName: "location"), for: .normal)
        btnGiftCard.setImage(UIImage(systemName: "giftcard"), for: .normal)
        btnContactUs.setImage(UIImage(systemName: "message"), for: .normal)
        btnCurrentPromos.setImage(UIImage(systemName: "tag"), for: .normal)
        btnPrivacy.setImage(UIImage(systemName: "hand.raised"), for: .normal)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let theSite = getSite()
        let selectedOption = optionArray[indexPath.row]
        
        if (checkNet() == false){
            return
        }
        
        if selectedOption.contains("Buy") {
            if (!isLoggedIn){
                showIt(title: "Please Log In", msg: "Please log in to make a purchase.")
                return
            }
            performSegue(withIdentifier: "PayPal", sender: nil)
        }
        
        else if selectedOption.contains("Automatic") {
            if (theSite == 3){
                performSegue(withIdentifier: "showAutomatica", sender: nil)
            }
            else if (theSite == 4){
                performSegue(withIdentifier: "showAutomaticl", sender: nil)
            }
        }
        
        else if selectedOption.contains("Bay") {
            if (theSite == 1){
                performSegue(withIdentifier: "UseCoinBay", sender: nil)
            }
            else if (theSite == 2){
                performSegue(withIdentifier: "UseCoinBay2", sender: nil)
            }
            else if (theSite == 3){
                performSegue(withIdentifier: "UseCoinBay3", sender: nil)
            }
            else if (theSite == 4){
                performSegue(withIdentifier: "UseCoinBay4", sender: nil)
            }
        }
        
        else if selectedOption.contains("Vacuum") {
            if (theSite == 1){
                performSegue(withIdentifier: "UseVacuum", sender: nil)
            }
            else if (theSite == 2){
                performSegue(withIdentifier: "UseVacuum2", sender: nil)
            }
            else if (theSite == 3){
                performSegue(withIdentifier: "UseVacuum3", sender: nil)
            }
            else if (theSite == 4){
                performSegue(withIdentifier: "UseVacuum4", sender: nil)
            }
        }
        
        else if selectedOption.contains("Code") {
            performSegue(withIdentifier: "WashCode", sender: nil)
        }
        
        else if selectedOption.contains("Log") {
            performSegue(withIdentifier: "login", sender: nil)
            btnLogInOutClicked()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return optionArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = UIColor.clear
        return footerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 60  // Adjust this value for more/less space
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let margin: CGFloat = 25
        let spacing: CGFloat = 15
        
        cell.contentView.backgroundColor = .clear
        let backgroundView = UIView(frame: CGRect(x: margin, y: spacing / 2, width: tableView.bounds.width - (margin * 2), height: cell.bounds.height - spacing))
              
        
        backgroundView.backgroundColor = myGrey
        backgroundView.layer.cornerRadius = 10
        backgroundView.layer.masksToBounds = true
        
        // Add blue border
        backgroundView.layer.borderWidth = 0.5
        backgroundView.layer.borderColor = navyBlue.cgColor
        let backgroundContainer = UIView()
        backgroundContainer.addSubview(backgroundView)
        cell.backgroundView = backgroundContainer
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
       
       // Clear any existing subviews
       cell.contentView.subviews.forEach { $0.removeFromSuperview() }
       
       // Hide default imageView and textLabel
       cell.imageView?.image = nil
       cell.textLabel?.text = ""
       
       // Create custom icon with white circle background
       let iconImageView = UIImageView()
       iconImageView.image = UIImage(systemName: iconsArray[indexPath.row])
       iconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
       iconImageView.tintColor = navyBlue
       iconImageView.contentMode = .center
       iconImageView.backgroundColor = UIColor.white
       iconImageView.layer.cornerRadius = 20  // Half of 30 for perfect circle
       iconImageView.layer.borderWidth = 0
       iconImageView.layer.borderColor = navyBlue.cgColor
       iconImageView.clipsToBounds = true
       iconImageView.translatesAutoresizingMaskIntoConstraints = false
       
       // Create custom label
       let label = UILabel()
       label.text = optionArray[indexPath.row]
       label.font = UIFont.systemFont(ofSize: 18, weight: .regular)
       label.textColor = UIColor.label
       label.translatesAutoresizingMaskIntoConstraints = false
       
       cell.contentView.addSubview(iconImageView)
       cell.contentView.addSubview(label)
       
       // Position icon and text
       NSLayoutConstraint.activate([
           iconImageView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 50),
           iconImageView.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
           iconImageView.widthAnchor.constraint(equalToConstant: 40),  // Increased for circle
           iconImageView.heightAnchor.constraint(equalToConstant: 40), // Increased for circle
           
           label.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 15),
           label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
       ])
       
       // Create custom blue chevron
       let chevronContainer = UIView(frame: CGRect(x: 0, y: 0, width: 32, height: 20))
       let chevronImageView = UIImageView(frame: CGRect(x: -10, y: 0, width: 12, height: 20))
       
       chevronImageView.image = UIImage(systemName: "chevron.right")
       chevronImageView.tintColor = navyBlue
       chevronImageView.contentMode = .center
       
       chevronContainer.addSubview(chevronImageView)
       cell.accessoryView = chevronContainer
       
       cell.selectionStyle = .none
       cell.backgroundColor = .clear
       
       return cell
    }
    
    func checkNet() -> Bool {
        if !(ViewController.isConnectedToNetwork())
        {
            noInternet()
            netConnected = false
            return false
        }
        else {
            netConnected = true
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
        if (!saveTokenOnce) {
            debugPrint("saveTokenOnce set to true")
            Messaging.messaging().token { token, error in
                if error != nil {
                    self.debugPrint("Error fetching FCM registration token")
                } else if let token = token {
                    self.debugPrint("FCM registration token: \(token)")
                    ViewController.fcmToken(token)
                }
            }
            Messaging.messaging().subscribe(toTopic: "all")
            debugPrint("subscribed to topic all")
        }
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
    
    func resetPassword (email:String){
        Auth.auth().sendPasswordReset(withEmail: email) {
            error in
            if error != nil {
                //print(error!)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.handleFirebaseError(error! as NSError)
                }
            }
            else {
                self.showIt(title: "Success", msg: "A link to reset your password has been sent to " + email)
            }
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
        super.viewDidAppear(animated)          // always call super first

        // Safer lookup: returns false if the key doesn’t exist
        if UserDefaults.standard.bool(forKey: "checkBalance") {
            getBalance()
            // It looks like you meant to reset *checkBalance* instead of *coinAdd* here
            UserDefaults.standard.set(false, forKey: "checkBalance")
        }

        // Fire-and-forget after the view is on-screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.saveToken()
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
                if(isLoggedIn){
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
    
    func btnLogInOutClicked() {
        savedCard = ""
        hasSavedCard = false

        if (isLoggedIn){
            wasLoggedIn = justLoggedOut
            //showIt(title: "Success", msg: "You have been successfully logged out.")
            UserDefaults.standard.set(false, forKey: "loggedIn")
            UserDefaults.standard.set("", forKey: "userId")
            self.lblAccountBalance.text = "Account Balance $0.00"
            self.lblReward.text = points + "0 Reward Points"
            isLoggedIn = false;
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
                            self.handleFirebaseError(error! as NSError)
                        } else {
                            self.showIt(title: "Success", msg: "A link to reset your password has been sent.")
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
    
    func closeItFast() {
        leadingCon.constant = 0
        trailingCon.constant = 0
        menuVisible = false
        menu.title = "Menu"
    }
    
    static func fixButton (_ button: UIButton) {
        button.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping;
        button.titleLabel?.textAlignment = NSTextAlignment.center
        button.setTitleColor(UIColor.black, for:UIControl.State())
        button.titleLabel!.font = UIFont.systemFont(ofSize: 18)
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 0.5
        button.layer.backgroundColor = (myGrey).cgColor
        button.layer.borderColor = UIColor.blue.cgColor
       
        // Add chevron to the right
        //let chevronConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        //let chevronImage = UIImage(systemName: "chevron.right", withConfiguration: chevronConfig)
        //button.setImage(chevronImage, for: .normal)
        //button.tintColor = UIColor.blue
        //button.semanticContentAttribute = .forceRightToLeft  // Puts image on right side
        //button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: -10)
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
                showIt(title: "Please Log In", msg: "Please log in to view your account details.")
            }
        }
        else {
            showIt(title: "Please Log In", msg: "Please log in to view your account details.")
        }
    }
    
    @IBAction func btnContactClicked(_ sender: Any) {
        if (checkNet() == false){
            return
        }
        
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
                showIt(title: "Please Log In", msg: "Please log in to redeem a gift card.")
            }
        }
        else {
            showIt(title: "Please Log In", msg: "Please log in to redeem a gift card.")
        }
    }
    
    @IBAction func btnSelectLocationClicked(_ sender: Any) {
        self.performSegue(withIdentifier: "showLocation", sender: nil)
        closeItFast()
    }

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
        if (token.count > 5 && isConnectedToNetwork() && saveTokenOnce == false) {
            saveTokenOnce = true
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
            if (myDebug){
                print(id + " " + token)
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
                        let myResult = parseJSON["tResult"] as? String
                        if (myResult == "1") {
                            if (myDebug){
                                print("server saved fcmToken successfully")
                            }
                        }
                        else{
                            if (myDebug){
                                print("server FAILED to save fcmToken")
                            }
                        }
                    }
                }
                catch {
                    if (myDebug){
                        print(error)
                    }
                    
                }
            })
            task.resume()
        }
        else {
            if (myDebug){
                print("Token already saved, not saving again.")
            }
        }
    }
    
    func getBalance () {
        if (checkNet()) {
            if(isLoggedIn) {
                pleaseWait()
                let didPay = UserDefaults.standard.object(forKey: "paypal") as! Bool
                if (didPay) {
                    alert.message = "\nChecking for a recent PayPal purchase. \n\nThis will take a moment."
                    UserDefaults.standard.set(false, forKey: "paypal")
                    Timer.scheduledTimer(timeInterval: 7.0, target: self, selector: #selector(balanceDelayedAction), userInfo: nil, repeats: false)
                }
                else {
                    alert.message = "This may take a moment"
                    Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(balanceDelayedAction), userInfo: nil, repeats: false)
                }
                
            }
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
    
    func showIt(title:String, msg:String) {
        var newTitle = "Oops..."
        if (title != ""){
            newTitle = title
        }
        let dialogMessage = UIAlertController(title: newTitle, message: msg, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            
        })
        dialogMessage.addAction(ok)
        self.present(dialogMessage, animated: true, completion: nil)
    }
    
    func isValidEmail(_ testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        if (emailTest.evaluate(with: testStr))
        {
            return true
        }
        return false
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
    
    @objc func logIn(email: String, password: String) {
        pleaseWait()
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            self.endWait()

            if let error = error as NSError? {
                // Handle Firebase authentication errors
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.handleFirebaseError(error)
                }
                return
            }

            guard let user = authResult?.user else {
                self.showIt(title: "Oops...", msg: "Unexpected login error. Please try again.")
                return
            }

            // Successful login
            checkBalance = true
            userId = user.uid
            UserDefaults.standard.set(userId, forKey: "userId")
            UserDefaults.standard.set(true, forKey: "loggedIn")
            UserDefaults.standard.set(email, forKey: "userEmail")
            isLoggedIn = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                self.performSegue(withIdentifier: "home", sender: self)
            }
        }
    }

    @objc func endWait(){
        DispatchQueue.main.async(execute: { () -> Void in
            self.dismiss(animated: false, completion: nil)
        })
    }
    
    func pleaseWait() {
        DispatchQueue.main.async {
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
            alert.view.tintColor = UIColor.black
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = .large
            loadingIndicator.color = .red
            loadingIndicator.startAnimating()
            alert.view.addSubview(loadingIndicator)
            self.present(alert, animated: true, completion: nil)
        }
    }

    
    func handleFirebaseError(_ error: NSError) {
        guard let errorCode = AuthErrorCode(rawValue: error.code) else {
            showIt(title: "Oops...", msg: "An unknown error occurred. Please try again.")
            return
        }

        let message: String

        switch errorCode {
        case .wrongPassword:
            message = "The password is incorrect. Please try again."
        case .userNotFound:
            message = "No account found with that email. Please check and try again."
        case .emailAlreadyInUse:
            message = "This email address is already in use. Please use a different one."
        case .invalidEmail:
            message = "The email address format is invalid. Please check and try again."
        case .weakPassword:
            message = "Your password is too weak. Please use a stronger password."
        case .networkError:
            message = "A network error occurred. Please check your connection and try again."
        default:
            message = "Something went wrong. Please try again."
        }

        showIt(title: "Oops...", msg: message)
    }
    
    func isConnectedToNetwork() -> Bool {
        if (netConnected){
            return netConnected
        }
        showIt(title:"No Internet Connection", msg: "Please check your network connection and try again.")
        return netConnected
    }
    
    func registerUser(_ type:String, firstName:String, lastName:String, email:String, password:String, phoneNumber:String) {
        if(isConnectedToNetwork()) {
            
            pleaseWait()
            var dictionary = [String: String]()
            let myUrl = URL(string: "r" )! //"web_url + "register")!
            //print (myUrl)
            if (phoneNumber.count > 5){
                dictionary = ["k":""]//APP_KEY, "c":APP_CLIENT, "s":SITE, "plat":PLATFORM, "fn":firstName, "ln":lastName, "p":password, "e":email, "pn":phoneNumber ]
            }
            else {
                dictionary = ["k":""]//APP_KEY, "c":APP_CLIENT, "s":SITE, "plat":PLATFORM, "fn":firstName, "ln":lastName, "p":password, "e":email ]
            }
            
            //print (dictionary)
            var request = URLRequest(url:myUrl);
            request.httpMethod = "POST";
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
            let task = URLSession.shared.dataTask(with: request, completionHandler: {
                data, response, error in
                
                if error != nil
                {
                    self.endWait()
                    print("in the error")
                    print("error=\(String(describing: error))")
                    return
                }
                do {
                    self.endWait()
                    //print(String(data: data!, encoding: .utf8)!)
                    
                    //var theData = String(data: data!, encoding: .utf8)!
                    //var newData = Data(theData.utf8)
                    
                    let json = try? JSONSerialization.jsonObject(with: data!, options: [])
                    var goodResult = false
                    // var error = ""
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
                            if let localId = dictionary["localId"] as? String {
                                userId = localId
                                UserDefaults.standard.set(true, forKey: "loggedIn")
                                UserDefaults.standard.set(userId, forKey: "userId")
                                UserDefaults.standard.set(email, forKey: "userEmail")
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                self.performSegue(withIdentifier: "home", sender: self)
                            }
                        }
                        else{
                            if let error = dictionary["error"] as? String {
                                if (error == "EMAIL_EXISTS"){
                                    self.showIt(title: "", msg: "An account with this email address already exists")
                                }
                                else {
                                    self.showIt(title: "", msg: error)
                                }
                            }
                        }
                    }
                }
                
            })
            task.resume()
        }
        
    }
    
    func debugPrint(_ message: String) {
        if myDebug {
            print(message)
        }
    }
    
}
