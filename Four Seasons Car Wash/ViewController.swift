//
//  ViewController.swift
//  Four Seasons Car Wash
//
//  Created by Paul Di Domenico on 2016-09-28.
//  Copyright © 2016 Tech1st Wash Systems. All rights reserved.
//

import UIKit
import FirebaseAuth
import MapKit
import CoreLocation
import SystemConfiguration

let service = "https://www.t1serv.com/fourseasons/cw.svc/"
var savedCard = "";
var hasSavedCard = false
let newOpen = 0
let justLoggedOut = 1
let alreadyLoggedOut = 2
var wasLoggedIn = newOpen
var moveToLoginOnceCompleted = false;
// var onSite = true
// var distance = 0.00
var userId = ""
var userEmail = ""
var isLoggedIn = false
let navyBlue = UIColor(red: 0x30/255.0, green: 0x3F/255.0, blue: 0x9F/255.0, alpha: 1.0)
let myGrey = UIColor(red: 0.933, green: 0.933, blue: 0.933, alpha: 1.0)
let myDebug = false

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var email = ""
    var pass = ""
    var phoneNumber = ""
    var userId = ""
    var gotFreeCode = false
    var giveFreeCode = false
    //var locationManager = CLLocationManager()
    var menuVisible = false
    private var accountSessionObserver: NSObjectProtocol?
    private var appDidBecomeActiveObserver: NSObjectProtocol?
    private var isHomeVisible = false
    private var balanceRefreshSession: AccountSession.Snapshot?
    private var balanceRefreshWorkItem: DispatchWorkItem?
    private var balanceDataTask: URLSessionDataTask?
    private var balanceProgressAlert: UIAlertController?
    private var balanceRefreshWasPayPal = false
    private var hasShownOfflineBalanceNotice = false
    private var savedCardRefreshID: UUID?
    private var savedCardDataTask: URLSessionDataTask?

    private struct BalanceResponse {
        let balance: String
        let rewardPoints: String
    }
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
    private static var hasRunThisSession = false
    private static var activeSavedCardRefreshID: UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //locationManager.delegate = self
        //locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //locationManager.requestWhenInUseAuthorization()
        //locationManager.startUpdatingLocation()
        
        if !ViewController.hasRunThisSession {
            ViewController.hasRunThisSession = true
            UserDefaults.standard.set(false, forKey: "coinAdd")
            AccountBalanceStore.markRefreshRequired()
            //print("Once Only")
        }
        
        accountSessionObserver = NotificationCenter.default.addObserver(
            forName: .accountSessionDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.syncAccountSessionFromCoordinator()
        }
        appDidBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self, self.isHomeVisible else { return }
            self.resumeBalanceRefreshIfNeeded()
        }
        syncAccountSessionFromCoordinator()
        
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
        //print("DidLoad")
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
        syncAccountSessionFromCoordinator()
        
        var logInOutButton = "Log In / Sign Up"
        var lockIcon = "lock.open"
        if (isLoggedIn){
            logInOutButton = "Log Out"
            lockIcon = "lock"
        }
                
        let mySite = getSite()
        if mySite == 3 || mySite == 4 {
            optionArray = ["Buy Now", "Use Touchless Automatic", "Use Wash Bay", "Use Vacuum", "Use Wash Code", logInOutButton]
            iconsArray = ["creditcard", "car", "drop", "car.top.door.front.left.open", "qrcode", lockIcon]
        } else {
            optionArray = ["Buy Now", "Use Wash Bay", "Use Vacuum", "Use Wash Code", logInOutButton]
            iconsArray = ["creditcard", "drop", "car.top.door.front.left.open", "qrcode", lockIcon]
        }
        UITableView.reloadData()
        
        btnHome.setImage(UIImage(systemName: "house"), for: .normal)
        btnMyAccount.setImage(UIImage(systemName: "person.circle"), for: .normal)
        btnSelectLocation.setImage(UIImage(systemName: "location"), for: .normal)
        btnGiftCard.setImage(UIImage(systemName: "giftcard"), for: .normal)
        btnContactUs.setImage(UIImage(systemName: "message"), for: .normal)
        btnCurrentPromos.setImage(UIImage(systemName: "tag"), for: .normal)
        btnPrivacy.setImage(UIImage(systemName: "hand.raised"), for: .normal)
        //print("WillAppear")
    }

    deinit {
        if Thread.isMainThread,
           let session = balanceRefreshSession,
           AccountSession.isCurrent(session) {
            AccountBalanceStore.markRefreshRequired()
        }
        balanceRefreshWorkItem?.cancel()
        balanceDataTask?.cancel()
        if ViewController.activeSavedCardRefreshID == savedCardRefreshID {
            ViewController.activeSavedCardRefreshID = nil
        }
        savedCardDataTask?.cancel()
        if let accountSessionObserver = accountSessionObserver {
            NotificationCenter.default.removeObserver(accountSessionObserver)
        }
        if let appDidBecomeActiveObserver = appDidBecomeActiveObserver {
            NotificationCenter.default.removeObserver(appDidBecomeActiveObserver)
        }
    }

    private func syncAccountSessionFromCoordinator() {
        let session = AccountSession.currentSnapshot()
        if let activeSession = balanceRefreshSession,
           !AccountSession.isCurrent(activeSession) {
            cancelBalanceRefresh()
        }

        userId = session?.userID ?? ""
        isLoggedIn = session != nil
        userEmail = session?.email ?? ""

        guard isViewLoaded else { return }
        renderCachedBalances(for: session)
        UITableView?.reloadData()

        if isHomeVisible, session != nil {
            resumeBalanceRefreshIfNeeded()
        }
    }

    private func renderCachedBalances(for session: AccountSession.Snapshot?) {
        guard let session = session else {
            if AccountSession.isAuthenticationStateResolved {
                lblAccountBalance.text = "Account Balance $0.00"
                lblReward.text = "0 Reward Points"
            }
            else {
                lblAccountBalance.text = "Account Balance"
                lblReward.text = "Reward Points"
            }
            return
        }

        if let cachedValues = AccountBalanceStore.cachedValues(for: session.userID) {
            lblAccountBalance.text = "Account Balance " + cachedValues.balance
            lblReward.text = cachedValues.rewardPoints + " Reward Points"
        }
        else {
            lblAccountBalance.text = "Account Balance"
            lblReward.text = "Reward Points"
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let theSite = getSite()
        let selectedOption = optionArray[indexPath.row]
        
        if (checkNet() == false){
            return
        }
        
        if selectedOption.contains("Buy") {
            guard AccountSession.currentSnapshot() != nil else {
                showIt(title: "Please Log In", msg: "Please log in to make a purchase.")
                return
            }
            performSegue(withIdentifier: "PayPal", sender: nil)
        }
        
        else if selectedOption.contains("Automatic") {
            if (!isLoggedIn){
                showIt(title: "Please Log In", msg: "Please log in to use the automatic wash.")
                return
            }
            if (theSite == 3){
                performSegue(withIdentifier: "showAutomatica", sender: nil)
            }
            else if (theSite == 4){
                performSegue(withIdentifier: "showAutomaticl", sender: nil)
            }
        }
        
        else if selectedOption.contains("Bay") {
            if (!isLoggedIn){
                showIt(title: "Please Log In", msg: "Please log in to use the wash bays.")
                return
            }
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
            if (!isLoggedIn){
                showIt(title: "Please Log In", msg: "Please log in to use the vacuums.")
                return
            }
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
            if AccountSession.currentSnapshot() != nil {
                btnLogInOutClicked()
            }
            else {
                performSegue(withIdentifier: "login", sender: nil)
            }
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
        guard ViewController.isConnectedToNetwork() else {
            noInternet()
            return false
        }
        return true
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
        guard let defaultRouteReachability = defaultRouteReachability,
              SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) else {
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
        super.viewDidAppear(animated)          // always call super first
        isHomeVisible = true
        resumeBalanceRefreshIfNeeded()
    }

    private func resumeBalanceRefreshIfNeeded() {
        if AccountBalanceStore.retryPromptPending,
           AccountBalanceStore.automaticRetrySuppressed {
            showBalanceRefreshFailure()
            return
        }
        refreshBalanceIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isHomeVisible = false
        if isMovingFromParent || navigationController?.isBeingDismissed == true {
            cancelBalanceRefresh(preserveIntentIfCurrent: true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func refreshSavedCard(for session: AccountSession.Snapshot) {
        savedCardDataTask?.cancel()
        savedCardDataTask = nil
        let refreshID = UUID()
        savedCardRefreshID = refreshID
        ViewController.activeSavedCardRefreshID = refreshID
        savedCard = ""
        hasSavedCard = false

        guard AccountSession.isCurrent(session),
              let myUrl = URL(string: service + "gcv2"),
              let body = try? JSONSerialization.data(withJSONObject: [
                  "u": session.userID,
                  "k": "eCCz3918mNme"
              ]) else {
            savedCardRefreshID = nil
            if ViewController.activeSavedCardRefreshID == refreshID {
                ViewController.activeSavedCardRefreshID = nil
            }
            return
        }

        var request = URLRequest(url: myUrl)
        request.timeoutInterval = 15.0
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            var validatedCard: String?
            if error == nil,
               (response as? HTTPURLResponse)?.statusCode == 200,
               let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let result = json["gcv2Result"] as? String {
                let fields = result.components(separatedBy: ",")
                if fields.count == 4,
                   fields[0] == "1",
                   fields[1].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
                   fields[2].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
                   fields[3].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    validatedCard = result
                }
            }

            DispatchQueue.main.async {
                guard let self = self,
                      self.savedCardRefreshID == refreshID,
                      ViewController.activeSavedCardRefreshID == refreshID else {
                    return
                }
                self.savedCardDataTask = nil
                self.savedCardRefreshID = nil
                ViewController.activeSavedCardRefreshID = nil
                guard AccountSession.isCurrent(session) else { return }
                savedCard = validatedCard ?? ""
                hasSavedCard = validatedCard != nil
            }
        }
        savedCardDataTask = task
        task.resume()
    }
    
    @IBAction func payPalClicked(_ sender: Any) {
        if (getSite() != 0) {
            if (checkNet()) {
                if AccountSession.currentSnapshot() != nil {
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
        guard AccountSession.currentSnapshot() != nil else { return }
        wasLoggedIn = justLoggedOut
        AccountSession.logOut { [weak self] cleanupSucceeded in
            guard let self = self else { return }
            self.lblAccountBalance.text = "Account Balance $0.00"
            self.lblReward.text = "0 Reward Points"
            ViewController.hasRunThisSession = false

            if cleanupSucceeded {
                self.performSegue(withIdentifier: "login", sender: self)
            }
            else {
                self.showIt(
                    title: "Secure cleanup incomplete",
                    msg: "The previous secure session could not be cleared. Please restart the app before logging in."
                )
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
    
    @IBAction func btnHomeClicked(_ sender: Any) {
        if menuVisible {
            leadingCon.constant = 0
            trailingCon.constant = 0
            menuVisible = false
            menu.title = "Menu"
            
            UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveEaseIn, animations: {
                self.view.layoutIfNeeded()
            }) { (animationComplete) in
            }
        }
    }
    
    @IBAction func btnMyAccountClicked(_ sender: Any) {
        if AccountSession.currentSnapshot() != nil {
            performSegue(withIdentifier: "MyAccount", sender: nil)
            closeItFast()
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
        if (checkNet() == false){
            return
        }
        
        ViewController.theUrl = "https://tech1st.ca/app/privacy.aspx?wash=camera"
        self.performSegue(withIdentifier: "showWeb", sender: nil)
        closeItFast()
    }
    
    @IBAction func btnRedeemGiftCardClicked(_ sender: Any) {
        if (checkNet() == false){
            return
        }
        
        if AccountSession.currentSnapshot() != nil {
            AccountBalanceStore.markRefreshRequired()
            performSegue(
                withIdentifier: "showWeb",
                sender: UidHandoff.Destination.gift
            )
            closeItFast()
        }
        else {
            showIt(title: "Please Log In", msg: "Please log in to redeem a gift card.")
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showWeb",
              let destination = sender as? UidHandoff.Destination,
              let webController = segue.destination as? webby else {
            return
        }
        webController.handoffDestination = destination
    }
    
    @IBAction func btnSelectLocationClicked(_ sender: Any) {
        self.performSegue(withIdentifier: "showLocation", sender: nil)
        closeItFast()
    }

    @IBAction func btnCurrentPromotionsClicked(_ sender: Any) {
        if (checkNet() == false){
            return
        }

        ViewController.theUrl = "https://tech1app.com/fourseasons/promoboard.aspx?pass=coolpass"
        self.performSegue(withIdentifier: "showWeb", sender: nil)
        closeItFast()
    }
    
    private func refreshBalanceIfNeeded() {
        let defaults = UserDefaults.standard
        guard isHomeVisible,
              defaults.bool(forKey: AccountBalanceStore.refreshRequiredKey),
              !AccountBalanceStore.automaticRetrySuppressed,
              balanceRefreshSession == nil,
              let session = AccountSession.currentSnapshot() else {
            return
        }
        guard ViewController.isConnectedToNetwork() else {
            if !hasShownOfflineBalanceNotice {
                hasShownOfflineBalanceNotice = true
                view.makeToast(
                    message: "Account details will refresh when you reconnect and return to the app."
                )
            }
            return
        }

        hasShownOfflineBalanceNotice = false
        balanceRefreshSession = session
        defaults.set(false, forKey: AccountBalanceStore.refreshRequiredKey)

        let didPay = defaults.bool(forKey: "paypal")
        balanceRefreshWasPayPal = didPay

        // When Home owns a refresh spinner, start balance work only after that
        // alert finishes presenting so response dismissal cannot race it.
        showBalanceProgress(didPay: didPay) { [weak self] in
            self?.startBalanceRequest(for: session, didPay: didPay)
        }
    }

    private func startBalanceRequest(
        for session: AccountSession.Snapshot,
        didPay: Bool
    ) {
        guard balanceRefreshSession == session else { return }

        guard didPay else {
            fetchBalance(for: session)
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.fetchBalance(for: session)
        }
        balanceRefreshWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0, execute: workItem)
    }

    private func showBalanceProgress(
        didPay: Bool,
        completion: @escaping () -> Void
    ) {
        guard balanceProgressAlert == nil, presentedViewController == nil else {
            // Another modal already owns presentation; refresh without adding
            // a spinner that this controller cannot safely present.
            completion()
            return
        }

        let message = didPay
            ? "\nChecking for a recent PayPal purchase.\n\nThis will take a moment."
            : "\nRefreshing your account..."
        let progress = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let indicator = UIActivityIndicatorView(
            frame: CGRect(x: 10, y: 5, width: 50, height: 50)
        )
        indicator.hidesWhenStopped = true
        indicator.style = .large
        indicator.color = .red
        indicator.startAnimating()
        progress.view.addSubview(indicator)
        balanceProgressAlert = progress
        present(progress, animated: false) { [weak self] in
            // If cancellation retired this alert while it was presenting,
            // dismiss that exact instance after the transition instead of
            // starting work for the retired refresh.
            guard let self = self, self.balanceProgressAlert === progress else {
                progress.dismiss(animated: false, completion: nil)
                return
            }
            completion()
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  self.balanceProgressAlert === progress,
                  progress.presentingViewController == nil else {
                return
            }

            // UIKit established no presentation relationship, so no
            // presentation completion can start this attempt. Preserve the
            // refresh for the next legitimate lifecycle trigger.
            self.cancelBalanceRefresh(preserveIntentIfCurrent: true)
        }
    }

    private func fetchBalance(for session: AccountSession.Snapshot) {
        balanceRefreshWorkItem = nil
        guard balanceRefreshSession == session, AccountSession.isCurrent(session) else {
            cancelBalanceRefresh()
            return
        }

        refreshSavedCard(for: session)
        guard let url = URL(string: service + "butp"),
              let body = try? JSONSerialization.data(withJSONObject: [
                  "i": session.userID,
                  "k": "eCCz3918mNme"
              ]) else {
            finishBalanceRefresh(for: session, response: nil)
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15.0
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            let parsedResponse = ViewController.parseBalanceResponse(
                data: data,
                response: response,
                error: error
            )
            DispatchQueue.main.async {
                self?.finishBalanceRefresh(for: session, response: parsedResponse)
            }
        }
        balanceDataTask = task
        task.resume()
    }

    private static func parseBalanceResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) -> BalanceResponse? {
        guard error == nil,
              let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode),
              let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["butpResult"] as? String else {
            return nil
        }

        return parseBalanceResult(result)
    }

    private static func parseBalanceResult(_ result: String) -> BalanceResponse? {
        let value = result.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let pointsSeparator = value.lastIndex(of: ",") else { return nil }

        let pointsText = String(value[value.index(after: pointsSeparator)...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let balanceAndType = value[..<pointsSeparator]
        guard let typeSeparator = balanceAndType.lastIndex(of: ",") else { return nil }

        let userTypeText = String(
            balanceAndType[balanceAndType.index(after: typeSeparator)...]
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        let rawBalance = String(balanceAndType[..<typeSeparator])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard Int(userTypeText) != nil,
              let parsedPoints = Int(pointsText),
              parsedPoints >= 0 else {
            return nil
        }
        guard let canonicalBalance = canonicalDollarBalance(rawBalance) else { return nil }

        return BalanceResponse(
            balance: canonicalBalance,
            rewardPoints: String(parsedPoints)
        )
    }

    private static func canonicalDollarBalance(_ rawBalance: String) -> String? {
        var value = rawBalance.trimmingCharacters(in: .whitespacesAndNewlines)
        var isNegative = false

        if value.hasPrefix("("), value.hasSuffix(")") {
            isNegative = true
            value.removeFirst()
            value.removeLast()
        }
        if value.hasPrefix("-") {
            guard !isNegative else { return nil }
            isNegative = true
            value.removeFirst()
        }
        guard value.hasPrefix("$") else { return nil }
        value.removeFirst()
        if value.hasPrefix("-") {
            guard !isNegative else { return nil }
            isNegative = true
            value.removeFirst()
        }

        let decimalParts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard decimalParts.count == 2 else { return nil }
        let wholePart = String(decimalParts[0])
        let cents = String(decimalParts[1])
        guard cents.count == 2, isASCIIDigits(cents) else { return nil }

        let groups = wholePart
            .split(separator: ",", omittingEmptySubsequences: false)
            .map(String.init)
        guard !groups.isEmpty else { return nil }
        if groups.count == 1 {
            guard isASCIIDigits(groups[0]) else { return nil }
        }
        else {
            guard (1...3).contains(groups[0].count),
                  isASCIIDigits(groups[0]),
                  groups.dropFirst().allSatisfy({
                      $0.count == 3 && isASCIIDigits($0)
                  }) else {
                return nil
            }
        }

        let joinedDollars = groups.joined()
        let nonzeroDollars = joinedDollars.drop(while: { $0 == "0" })
        let dollars = nonzeroDollars.isEmpty ? "0" : String(nonzeroDollars)
        let unsignedAmount = dollars + "." + cents
        let signedAmount = (isNegative ? "-" : "") + unsignedAmount
        guard let parsedAmount = Double(signedAmount), parsedAmount.isFinite else {
            return nil
        }
        return "$" + signedAmount
    }

    private static func isASCIIDigits(_ value: String) -> Bool {
        guard !value.isEmpty else { return false }
        return value.unicodeScalars.allSatisfy {
            $0.value >= 48 && $0.value <= 57
        }
    }

    private func finishBalanceRefresh(
        for session: AccountSession.Snapshot,
        response: BalanceResponse?
    ) {
        guard balanceRefreshSession == session else { return }
        balanceDataTask = nil

        guard AccountSession.isCurrent(session) else {
            cancelBalanceRefresh()
            return
        }

        if let response = response {
            let newerRefreshPending = UserDefaults.standard.bool(
                forKey: AccountBalanceStore.refreshRequiredKey
            )
            if balanceRefreshWasPayPal, !newerRefreshPending {
                UserDefaults.standard.set(false, forKey: "paypal")
            }
            AccountBalanceStore.store(
                balance: response.balance,
                rewardPoints: response.rewardPoints,
                for: session.userID
            )
            lblAccountBalance.text = "Account Balance " + response.balance
            lblReward.text = response.rewardPoints + " Reward Points"
        }

        completeBalanceRefresh(
            for: session,
            refreshFailed: response == nil
        )
    }

    private func completeBalanceRefresh(
        for session: AccountSession.Snapshot,
        refreshFailed: Bool
    ) {
        let completion = { [weak self] in
            guard let self = self, self.balanceRefreshSession == session else { return }
            let sessionIsCurrent = AccountSession.isCurrent(session)
            let newerRefreshPending = UserDefaults.standard.bool(
                forKey: AccountBalanceStore.refreshRequiredKey
            )
            if refreshFailed, sessionIsCurrent {
                AccountBalanceStore.preserveFailedRefresh()
            }

            self.balanceProgressAlert = nil
            self.balanceRefreshWorkItem = nil
            self.balanceDataTask = nil
            self.balanceRefreshSession = nil
            self.balanceRefreshWasPayPal = false

            if newerRefreshPending, sessionIsCurrent, self.isHomeVisible {
                self.refreshBalanceIfNeeded()
            }
            else if refreshFailed, sessionIsCurrent, self.isHomeVisible {
                self.resumeBalanceRefreshIfNeeded()
            }
        }

        if let progress = balanceProgressAlert, progress.presentingViewController != nil {
            progress.dismiss(animated: false, completion: completion)
        }
        else {
            completion()
        }
    }

    private func showBalanceRefreshFailure() {
        guard AccountBalanceStore.retryPromptPending else { return }
        guard presentedViewController == nil else {
            view.makeToast(
                message: "Unable to refresh account details. Your saved values remain available."
            )
            return
        }
        AccountBalanceStore.consumeRetryPrompt()

        let alert = UIAlertController(
            title: "Account Refresh Failed",
            message: "Your saved balance and reward points are still shown. Would you like to try again?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Later", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            AccountBalanceStore.markRefreshRequired()
            self?.retryBalanceRefreshAfterAlertDismissal()
        })
        present(alert, animated: true, completion: nil)
    }

    private func retryBalanceRefreshAfterAlertDismissal(attemptsRemaining: Int = 10) {
        guard presentedViewController == nil else {
            guard attemptsRemaining > 0 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.retryBalanceRefreshAfterAlertDismissal(
                    attemptsRemaining: attemptsRemaining - 1
                )
            }
            return
        }
        refreshBalanceIfNeeded()
    }

    private func cancelBalanceRefresh(preserveIntentIfCurrent: Bool = false) {
        if preserveIntentIfCurrent,
           let session = balanceRefreshSession,
           AccountSession.isCurrent(session) {
            AccountBalanceStore.markRefreshRequired()
        }
        balanceRefreshWorkItem?.cancel()
        balanceDataTask?.cancel()
        balanceRefreshWorkItem = nil
        balanceDataTask = nil
        balanceRefreshSession = nil
        balanceRefreshWasPayPal = false

        if let progress = balanceProgressAlert {
            balanceProgressAlert = nil
            progress.dismiss(animated: false, completion: nil)
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
        returnToExistingHome(fallbackSegueIdentifier: "showHome")
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
            guard let session = AccountSession.currentSnapshot() else {
                view.makeToast(message: "Log in again to complete this transaction")
                return
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
            let myUrl = URL(string: service + "impwvforwashv2")!
            let dictionary = [
                "i": session.userID,
                "pa": purchaseAmount,
                "k": "8qlpCCz3Wxp4@4djka!!"
            ]

            var request = URLRequest(url: myUrl)
            request.httpMethod = "POST"
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(
                withJSONObject: dictionary,
                options: []
            )

            URLSession.shared.dataTask(with: request) {
                [weak self] data, response, error in
                var result: String?
                if error == nil,
                   (response as? HTTPURLResponse)?.statusCode == 200,
                   let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data)
                    as? [String: Any] {
                    result = json["impwvforwashv2Result"] as? String
                }

                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.dismiss(animated: false, completion: nil)
                    guard AccountSession.isCurrent(session) else {
                        self.view.makeToast(
                            message: "Your account session changed. Please try again."
                        )
                        return
                    }

                    if result == "Y" || result == "1" {
                        self.performSegue(withIdentifier: "showQRprep", sender: nil)
                    }
                    else {
                        self.view.makeToast(
                            message: "Cannot complete transaction \n Please try again"
                        )
                    }
                }
            }.resume()
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
    
    func returnToExistingHome(
        animated: Bool = true,
        fallbackSegueIdentifier: String = "home"
    ) {
        if let navigationController = navigationController,
           let homeController = navigationController.viewControllers.first(where: {
               $0 is ViewController
           }) {
            navigationController.popToViewController(homeController, animated: animated)
            return
        }

        performSegue(withIdentifier: fallbackSegueIdentifier, sender: self)
    }

    func logIn(
        email: String,
        password: String,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard let attemptID = AccountSession.beginAuthenticationAttempt() else {
            showIt(
                title: "Account Unavailable",
                msg: AccountSession.authenticationUnavailableMessage
            )
            completion?(false)
            return
        }

        let indicator = UIActivityIndicatorView(
            frame: CGRect(x: 10, y: 5, width: 50, height: 50)
        )
        let progress = UIAlertController(
            title: nil,
            message: "Please wait...",
            preferredStyle: .alert
        )
        indicator.style = .large
        indicator.color = .red
        indicator.startAnimating()
        progress.view.addSubview(indicator)

        present(progress, animated: true) { [weak self] in
            guard let self = self else {
                AccountSession.cancelAuthenticationAttempt(attemptID)
                completion?(false)
                return
            }

            Auth.auth().signIn(withEmail: email, password: password) {
                [weak self, weak progress] authResult, error in
                DispatchQueue.main.async {
                    guard let self = self else {
                        if AccountSession.isCurrentAuthenticationAttempt(attemptID) {
                            AccountSession.cancelAuthenticationAttempt(attemptID)
                        }
                        progress?.dismiss(animated: false, completion: nil)
                        completion?(false)
                        return
                    }
                    guard AccountSession.isCurrentAuthenticationAttempt(attemptID) else {
                        progress?.dismiss(animated: false, completion: nil)
                        completion?(false)
                        return
                    }
                    guard self.viewIfLoaded?.window != nil else {
                        AccountSession.cancelAuthenticationAttempt(attemptID)
                        progress?.dismiss(animated: false, completion: nil)
                        completion?(false)
                        return
                    }

                    if let error = error as NSError? {
                        AccountSession.cancelAuthenticationAttempt(attemptID)
                        progress?.dismiss(animated: false) {
                            self.handleFirebaseError(error)
                            completion?(false)
                        }
                        return
                    }
                    guard let user = authResult?.user,
                          AccountSession.completeAuthenticationAttempt(
                              attemptID,
                              user: user,
                              email: email
                          ) else {
                        progress?.dismiss(animated: false) {
                            self.showIt(
                                title: "Account Unavailable",
                                msg: "The signed-in account could not be verified. Please try again."
                            )
                            completion?(false)
                        }
                        return
                    }

                    progress?.dismiss(animated: false) {
                        completion?(true)
                        self.returnToExistingHome()
                    }
                }
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
        let isConnected = ViewController.isConnectedToNetwork()
        if !isConnected {
            showIt(
                title: "No Internet Connection",
                msg: "Please check your network connection and try again."
            )
        }
        return isConnected
    }
    
    func debugPrint(_ message: String) {
        if myDebug {
            print(message)
        }
    }
    
}
