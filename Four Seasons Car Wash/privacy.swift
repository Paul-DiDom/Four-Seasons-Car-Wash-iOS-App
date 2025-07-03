//
//  privacy.swift
//  Four Seasons Car Wash
//
//  Created by Paul Di Domenico on 2019-06-18.
//  Copyright © 2019 Tech1st Wash Systems. All rights reserved.
//

import UIKit
import WebKit

class privacy: UIViewController, WKUIDelegate {
  
    @IBOutlet weak var Webview: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = URL (string:"https://tech1st.ca/app/privacy.aspx?wash=camera")
        let request = URLRequest(url: url!)
        Webview.load(request)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        connecting()
    }    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
