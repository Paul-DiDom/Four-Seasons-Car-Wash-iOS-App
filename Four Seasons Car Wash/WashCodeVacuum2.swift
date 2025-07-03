//
//  WashCodeVacuum2.swift
//  Four Seasons Car Wash
//
//  Created by Paul Di Domenico on 2016-10-19.
//  Copyright © 2016 Tech1st Wash Systems. All rights reserved.
//

import UIKit

class WashCodeVacuum2: UIViewController , UIPickerViewDataSource, UIPickerViewDelegate
{
    //// Cornwall

    @IBOutlet var devicePicker: UIPickerView!
    @IBOutlet var btnEnterCode: UIButton!
    
    var devicePickerOptions = [String]();
    let device = "vacuum"
    let deviceUC = "Vacuum"
    let x = "CVAC"
    var deviceChosen = "0"
    var amountChosen = "Select"
    var deviceNum = 0
    let equipCode = "2"
    var myDeviceNum = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        ViewController.fixButton(btnEnterCode)
        btnEnterCode.isHidden = true
        self.devicePicker.dataSource = self
        self.devicePicker.delegate = self
        devicePickerOptions = ["Choose your "+device,"Use "+deviceUC+" 1", "Use "+deviceUC+" 2", "Use "+deviceUC+" 3", "Use "+deviceUC+" 4", "Use "+deviceUC+" 5", "Use "+deviceUC+" 6", "Use "+deviceUC+" 7", "Use "+deviceUC+" 8"];
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @IBAction func btnEnterCodeClicked(_ sender: AnyObject) {
        showKeypad()
    }

    
    func showKeypad() {
        let alert = UIAlertController(title: "Enter Wash Code", message: "Enter your code to start " + device + " " + myDeviceNum, preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { (textFieldCode) -> Void in
            textFieldCode.keyboardType = UIKeyboardType.numberPad
        })
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
            let textFieldCode = alert.textFields![0] as UITextField
            var code = ""
            code = textFieldCode.text!
            if (code.count == 6)
            {
                self.startRequest(type: "wc", deviceChosen:self.deviceChosen, amountChosen:"0", code:code, equip: self.equipCode)
            }
            else {
                self.view.makeToast(message: "Invalid wash code")
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel,handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return devicePickerOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(devicePickerOptions[row])"
    }
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        deviceNum = row
        myDeviceNum = String(row)
        deviceChosen = x + String(row)
        
        if (deviceChosen.contains("0")) {
            btnEnterCode.isHidden = true
        }
        else {
            btnEnterCode.isHidden = false
        }
        
    }
}
