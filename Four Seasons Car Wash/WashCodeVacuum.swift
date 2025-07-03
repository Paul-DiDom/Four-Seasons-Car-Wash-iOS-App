import UIKit

class WashCodeVacuum: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate
{
    //// Perth
    
    @IBOutlet var devicePicker: UIPickerView!
    @IBOutlet var btnEnterCode: UIButton!
    
    var devicePickerOptions = [String]();
    let device = "vacuum"
    let deviceUC = "Vacuum"
    let x = "PVAC"
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
        devicePickerOptions = ["Choose your "+device,"Use "+deviceUC+" 1", "Use "+deviceUC+" 2", "Use "+deviceUC+" 3", "Use "+deviceUC+" 4"];
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
                self.startRequest(type: "wc", deviceChosen: self.deviceChosen, amountChosen:"0", code:code, equip: self.equipCode)
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
