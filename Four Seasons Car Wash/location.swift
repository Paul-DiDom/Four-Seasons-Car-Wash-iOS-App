//
//  location.swift
//  Four Seasons Car Wash
//
//  Created by Paul Di Domenico on 2016-10-20.
//  Copyright © 2016 Tech1st Wash Systems. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging

class location: UIViewController , UIPickerViewDataSource, UIPickerViewDelegate{
    
    @IBOutlet var devicePicker: UIPickerView!
    @IBOutlet var btnConfirmLocation: UIButton!

    
    var devicePickerOptions = [String]();
    var deviceNum = 0
    var location = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        ViewController.fixButton(btnConfirmLocation)
        btnConfirmLocation.isHidden = true
        self.devicePicker.dataSource = self
        self.devicePicker.delegate = self
        devicePickerOptions = ["Select Location", "Perth", "Cornwall", "Arnprior", "Carleton Place"];
    }
    
    override func viewDidAppear(_ animated: Bool) {
        var mySite = 0
        if (UserDefaults.standard.object(forKey: "site") != nil)
        {
            mySite = UserDefaults.standard.object(forKey: "site") as! Int
        }
        if (mySite != 0) {
            devicePicker.selectRow(mySite, inComponent: 0, animated: false);
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func btnConfirmLocationClicked(_ sender: AnyObject) {
        UserDefaults.standard.set(deviceNum, forKey: "site")
        
        let l = String(deviceNum)

        if (deviceNum == 1) {
            Messaging.messaging().subscribe(toTopic: "perth")
            Messaging.messaging().unsubscribe(fromTopic: "cornwall")
            Messaging.messaging().unsubscribe(fromTopic: "arnprior")
            Messaging.messaging().unsubscribe(fromTopic: "carleton")
        }
        else if (deviceNum == 2) {
            Messaging.messaging().subscribe(toTopic: "cornwall")
            Messaging.messaging().unsubscribe(fromTopic: "perth")
            Messaging.messaging().unsubscribe(fromTopic: "arnprior")
            Messaging.messaging().unsubscribe(fromTopic: "carleton")
        }
        else if (deviceNum == 3) {
            Messaging.messaging().subscribe(toTopic: "arnprior")
            Messaging.messaging().unsubscribe(fromTopic: "perth")
            Messaging.messaging().unsubscribe(fromTopic: "carleton")
            Messaging.messaging().unsubscribe(fromTopic: "cornwall")
        }
        else if (deviceNum == 4) {
            Messaging.messaging().subscribe(toTopic: "carleton")
            Messaging.messaging().unsubscribe(fromTopic: "perth")
            Messaging.messaging().unsubscribe(fromTopic: "arnprior")
            Messaging.messaging().unsubscribe(fromTopic: "cornwall")
        }
        
        updateLOC(l)
        
        let alert = UIAlertController(title: "Location set", message: "Your default Four Seasons location is " + location, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
            _ = self.navigationController?.popToRootViewController(animated: true)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func updateLOC(_ l:String){
        print("updateLOC called with location: \(l)")
        
        var uid = ""
        if (UserDefaults.standard.object(forKey: "userId") != nil)
        {
            uid = UserDefaults.standard.object(forKey: "userId") as! String
            //print("User ID found: \(uid)")
        } else {
            //print("No User ID found in UserDefaults")
        }
        
        if (uid.count > 5) {
            //print("User ID is valid (length: \(uid.count))")
            
            let myUrl = URL(string: service + "loc")!
            //print("Making request to: \(myUrl)")
            
            var request = URLRequest(url:myUrl);
            request.httpMethod = "POST";
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let dictionary = ["u":uid, "l":l]
            //print("Request payload: \(dictionary)")
            
            request.httpBody = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
            
            let task = URLSession.shared.dataTask(with: request, completionHandler: {
                data, response, error in
                
                if error != nil {
                    //print("Network error: \(error!.localizedDescription)")
                    return
                }
                
                // Check HTTP response status
                if let httpResponse = response as? HTTPURLResponse {
                    //print("HTTP Status Code: \(httpResponse.statusCode)")
                    if httpResponse.statusCode != 200 {
                        //print("Non-200 status code received")
                    }
                }
                
                // Check if we have data
                guard let data = data else {
                    //print("No data received from server")
                    return
                }
                
                //print("Raw response data length: \(data.count) bytes")
                
                // Print raw response as string for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    //print("Raw response: \(responseString)")
                }
                
                do {
                    let myJSON = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? NSDictionary
                    if let parseJSON = myJSON {
                        //print("JSON parsed successfully: \(parseJSON)")
                        let myResult = parseJSON["locResult"] as? String
                        if let result = myResult {
                            //print("Location result: \(result)")
                            DispatchQueue.main.async(execute: { () -> Void in
                              // print("Final result on main thread: \(result)")
                            })
                        } else {
                            //print("No 'locResult' key found in response")
                        }
                    } else {
                        //print("Failed to parse JSON as NSDictionary")
                    }
                }
                catch {
                   //print("JSON parsing error: \(error)")
                }
            })
            task.resume()
            //print("Network task started")
        } else {
           // print("User ID is too short or empty (length: \(uid.count))")
        }
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
        
        if (row == 1) {
            location = "Perth"
        }
        else if (row == 2){
            location = "Cornwall"
        }
        else if (row == 3){
            location = "Arnprior"
        }
        else if (row == 4){
            location = "Carleton Place"
        }
        
        if (row == 0) {
            btnConfirmLocation.isHidden = true
        }
        else {
            btnConfirmLocation.isHidden = false
        }
    }
}
