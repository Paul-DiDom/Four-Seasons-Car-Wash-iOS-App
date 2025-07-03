//
//  washBusy.swift
//  Four Seasons Car Wash
//
//  Created by Paul Di Domenico on 2017-01-11.
//  Copyright © 2017 Tech1st Wash Systems. All rights reserved.
//

import UIKit

class washBusy: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        let alert = UIAlertController(title: "Not Ready", message: "There is a wash waiting to be processed.  Please try again when the instructions message on the teller does not say \"Please Wait \"", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
            Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.goHome), userInfo: nil, repeats: false)
        }))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
