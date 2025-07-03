//
//  WashCodeVacuumAutomaticA.swift
//  Four Seasons Car Wash
//
//  Created by Paul Di Domenico on 2017-01-08.
//  Copyright © 2017 Tech1st Wash Systems. All rights reserved.
//

import UIKit

class WashCodeVacuumAutomaticA: UIViewController {
    
    @IBOutlet var btnEnterCode: UIButton!
    let equipCode = "6" // Auto Teller
    let deviceChosen = "AWASH0"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        ViewController.fixButton(btnEnterCode)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @IBAction func btnEnterCodeClicked(_ sender: Any) {
        showKeypad()
    }
    
    
    func showKeypad() {
        let alert = UIAlertController(title: "Enter Wash Code", message: "Enter your touchless automatic code", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { (textFieldCode) -> Void in
            textFieldCode.keyboardType = UIKeyboardType.numberPad
        })
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
            let textFieldCode = alert.textFields![0] as UITextField
            var code = ""
            code = textFieldCode.text!
            if (code.count == 6)
            {
                self.startRequest(type: "wca", deviceChosen: self.deviceChosen, amountChosen:"0", code:code, equip: self.equipCode)
            }
            else {
                self.view.makeToast(message: "Invalid wash code")
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel,handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}
