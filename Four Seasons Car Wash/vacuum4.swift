//
//  vacuum4.swift
//  Four Seasons Car Wash
//
//  Created by Paul Di Domenico on 2017-01-04.
//  Copyright © 2017 Tech1st Wash Systems. All rights reserved.
//

import UIKit

class vacuum4: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate
    
{
    //// Carleton Place
    
    @IBOutlet var devicePicker: UIPickerView!
    @IBOutlet var amountPicker: UIPickerView!
    @IBOutlet var btnStart: UIButton!
    
    var userId = ""
    var balance = "$0"
    var bal = 0.00
    var devicePickerOptions = [String]();
    var amountPickerOptions = [String]();
    let device = "vacuum"
    let deviceUC = "Vacuum"
    let x = "LVAC"
    var deviceChosen = "0"
    var amountChosen = "amount"
    var deviceNum = 0
    let equipCode = "2"
    var needSavedCard = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        ViewController.fixButton(btnStart)
        btnStart.isHidden = true
        self.devicePicker.dataSource = self
        self.devicePicker.delegate = self
        self.amountPicker.dataSource = self
        self.amountPicker.delegate = self
        devicePickerOptions = ["Choose your "+device,"Use "+deviceUC+" 1", "Use "+deviceUC+" 2", "Use "+deviceUC+" 3", "Use "+deviceUC+" 4"];
        amountPickerOptions = ["Select an amount","$2.00", "$3.00", "$4.00", "$5.00","$6.00", "$7.00", "$8.00", "$9.00","$10.00","$11.00","$12.00", "$13.00", "$14.00", "$15.00", "$16.00", "$17.00", "$18.00", "$19.00", "$20.00"];
        devicePicker.tag = 1
        amountPicker.tag = 2
        
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
    
    @IBAction func btnStartBayClicked(_ sender: AnyObject) {
        if (needSavedCard && hasSavedCard && savedCard.contains(",")){
            let scArr = savedCard.components(separatedBy: ",")
            var cardType = scArr[1]
            let maskedPan = scArr[2]
            let exp = scArr[3]
            let pa = Double(amountChosen)! - bal
            
            cardType = getCardType(ct: cardType)
        
            let alert = UIAlertController(title: "Start " + deviceUC + " " + String(deviceNum) + " for " + amountChosen + " ?", message: "\nA purchase of $" + String(format: "%.2f", pa) + " is required.\n\nUse " + cardType + maskedPan + "\n\n with expiry " + exp + "?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) -> Void in
                self.startRequestWithPurchase(deviceChosen: self.deviceChosen, amountChosen: self.amountChosen, equip: self.equipCode, purchaseAmount: String(format: "%.2f", pa))
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel,handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        else {
            let alert = UIAlertController(title: "Start " + deviceUC + " " + String(deviceNum) + " for " + amountChosen + " ?", message: "This may take a moment.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) -> Void in
                self.startRequest(type: "t", deviceChosen: self.deviceChosen, amountChosen: self.amountChosen, code:"", equip: self.equipCode)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel,handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (pickerView.tag == 1){
            return devicePickerOptions.count
        }else{
            return amountPickerOptions.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if (pickerView.tag == 1){
            return "\(devicePickerOptions[row])"
        }else{
            return "\(amountPickerOptions[row])"
        }    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        if(pickerView.tag == 1)
        {
            deviceNum = row
            let myDevice = x + String(row)
            deviceChosen = myDevice
        }
        else
        {
            let amount = amountPickerOptions[row]
            amountChosen = amount
            amountChosen.remove(at: amountChosen.startIndex)
        }
        
        if (deviceChosen.contains("0")) || amountChosen.contains("amount") {
            btnStart.isHidden = true
        }
        else {
            if (bal >= Double(amountChosen)!) {
                btnStart.isHidden = false
                needSavedCard = false
            }
            else {
                needSavedCard = false
                if (bal == 0) {
                    if (hasSavedCard){
                        btnStart.isHidden = false
                        needSavedCard = true
                    }
                    else {
                        view.makeToast(message: "Your balance is $0.00")
                        btnStart.isHidden = true
                    }
                }
                else if (bal < Double(amountChosen)!) {
                    if (hasSavedCard){
                        btnStart.isHidden = false
                        needSavedCard = true
                    }
                    else {
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
}
