import UIKit

class TouchlessAutomatica: UIViewController,  UIPickerViewDataSource, UIPickerViewDelegate {
    
    //// Arnprior
    @IBOutlet var btnStart: UIButton!
    @IBOutlet var washPicker: UIPickerView!
    @IBOutlet var lblReward: UILabel!
    
    var wash = ""
    var userId = ""
    var balance = "$0"
    var bal = 0.00
    var removedChooseAmount = false
    var washPickerOptions = [String]();
    var amountChosen = ""
    var washChosen = 0;
    let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50)) as UIActivityIndicatorView
    let alert = UIAlertController(title: "Please wait...", message: "This may take a moment", preferredStyle: .alert)
    var needSavedCard = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        ViewController.fixButton(btnStart)
        btnStart.isHidden = true
        self.washPicker.dataSource = self
        self.washPicker.delegate = self
        
        washPickerOptions = ["Choose your wash","Speedy Wash", "Regular Wash", "Platinum Wash", "Platinum Plus"];
        
        if (UserDefaults.standard.object(forKey: "userId") != nil)
        {
            userId = UserDefaults.standard.object(forKey: "userId") as! String
        }
        if (UserDefaults.standard.object(forKey: "balance") != nil)
        {
            balance = UserDefaults.standard.object(forKey: "balance") as! String
            balance.remove(at: balance.startIndex)
            bal = Double(balance)!
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return washPickerOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(washPickerOptions[row])"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        washChosen = pickerView.selectedRow(inComponent: 0);
        let amount = washPickerOptions[row]
        amountChosen = amount
        amountChosen = String(amountChosen.suffix(5))
        amountChosen = amountChosen.replacingOccurrences(of: "$", with: "")
        amountChosen = amountChosen.trimmingCharacters(in: .whitespaces)
        
        if (amountChosen.range(of: "wash") != nil) {
            btnStart.isHidden = true
        }
        else {
            if (bal >= Double(amountChosen)! || (btnStart.currentTitle?.uppercased().contains("FREE"))!) {
                btnStart.isHidden = false
                wash = "AWASH" + String(washChosen)
                needSavedCard = false
            }
            else
            {
                needSavedCard = false
                if (bal == 0) {
                    if (hasSavedCard){
                        btnStart.isHidden = false
                        needSavedCard = true
                    }
                    else{
                        view.makeToast(message: "Your balance is $0.00")
                        btnStart.isHidden = true
                    }
                }
                else if (bal < Double(amountChosen)!) {
                    if (hasSavedCard){
                        btnStart.isHidden = false
                        needSavedCard = true
                    }
                    else{
                        view.makeToast(message: "Select an amount lower than $" + balance)
                        btnStart.isHidden = true
                    }
                }
                else {
                    btnStart.isHidden = true
                }
            }
        
        
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        getMenu()
    }
    
    func checkRemaining(){
        let myUrl = URL(string: service + "fbonus")!
        var request = URLRequest(url:myUrl);
        request.httpMethod = "POST";
        let equip = "WASH"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let dictionary = ["equip":equip, "user":userId]
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
                    let myResult = parseJSON["fbonusResult"] as? String
                    if (myResult == "" || myResult == "-1") {
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.lblReward.text = " "
                        })
                    }
                    else if (myResult == "0") {
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.lblReward.text = "You have earned a FREE wash"
                            self.btnStart.setTitle("Use Free Wash", for: UIControl.State.normal)
                        })
                    }
                    else if (myResult == "1") {
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.lblReward.text = "1 wash away from a free wash "
                        })
                    }
                    else  {
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.lblReward.text = myResult! + " washes away from a free wash"
                        })
                    }
                }
            }
            catch {
                
            }
        })
        task.resume()
    }
    
    func getMenu() {
        pleaseWait()
        let myUrl = NSURL(string: service + "amenu")!
        let request = NSMutableURLRequest(url:myUrl as URL);
        request.httpMethod = "POST";
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let dictionary = [String: String]()
        request.httpBody = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if error != nil
            {
                return
            }
            
            do {
                let myJSON = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? NSDictionary
                if let parseJSON = myJSON {
                    let myResult = parseJSON["amenuResult"] as? String
                    ///   print(myResult!)
                    let myWashArr = myResult!.components(separatedBy: ",")
                    let wash1 = myWashArr [0]
                    let wash2 = myWashArr [1]
                    let wash3 = myWashArr [2]
                    let wash4 = myWashArr [3]
                    if (wash4.range(of: "notinuse") != nil)
                    {
                        self.washPickerOptions = ["Choose your wash",wash1, wash2, wash3]
                    }
                    else {
                        self.washPickerOptions = ["Choose your wash",wash1, wash2, wash3, wash4]
                    }
                    self.endWait()
                    self.checkRemaining()
                }
            }
            catch {
                
            }
        }
        task.resume()
    }
    
    @IBAction func btnStartWashClicked(_ sender: Any) {
        if (needSavedCard && hasSavedCard && savedCard.contains(",")){
            
            let scArr = savedCard.components(separatedBy: ",")
            var cardType = scArr[1]
            let maskedPan = scArr[2]
            let exp = scArr[3]
            let pa = Double(amountChosen)! - bal
            
            cardType = getCardType(ct: cardType)
            let alert = UIAlertController(title: "Confirm Purchase", message: "\nA purchase of $" + String(format: "%.2f", pa) + " is required.\n\nUse " + cardType + maskedPan + "\n\n with expiry " + exp + "?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) -> Void in
                UserDefaults.standard.set(self.wash, forKey: "wash")
                UserDefaults.standard.set(self.amountChosen, forKey: "amount")
                UserDefaults.standard.set(true, forKey: "washChosen")
                self.startRequestForWashPurchase(purchaseAmount: String(format: "%.2f", pa))
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel,handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        else {
            UserDefaults.standard.set(wash, forKey: "wash")
            if (btnStart.currentTitle?.uppercased().contains("FREE"))! {
                UserDefaults.standard.set("0", forKey: "amount")
            }
            else {
                UserDefaults.standard.set(amountChosen, forKey: "amount")
            }
            UserDefaults.standard.set(true, forKey: "washChosen")
            self.performSegue(withIdentifier: "showQRprep", sender: nil)
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
    
    func endWait() {
        DispatchQueue.main.async {
            self.dismiss(animated: false, completion: nil)
            self.washPicker.reloadAllComponents();
        }
    }
    
}
