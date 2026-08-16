//
//  coinBayThanks.swift
//  Four Seasons Car Wash
//
//  Created by Paul Di Domenico on 2016-11-17.
//  Copyright © 2016 Tech1st Wash Systems. All rights reserved.
//

import UIKit
import AudioToolbox

class coinBayThanks: UIViewController {

    @IBOutlet var btnAdd: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        AccountBalanceStore.markRefreshRequired()
        UserDefaults.standard.set(true, forKey: "coinAdd")
        ViewController.fixButton(btnAdd)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func btnAddClicked(_ sender: AnyObject) {
        _ = navigationController?.popViewController(animated: true)
    }
    
}
