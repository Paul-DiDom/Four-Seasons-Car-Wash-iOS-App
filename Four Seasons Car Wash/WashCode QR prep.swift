import UIKit

class WashCode_QR_prep: UIViewController {
    
    @IBOutlet var btnReadyToScan: UIButton!
    @IBOutlet var btnCancel: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        ViewController.fixButton(btnReadyToScan)
        ViewController.fixButton(btnCancel)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func btnReadyToScanClicked(_ sender: AnyObject) {
        //if (onSite) {
        self.performSegue(withIdentifier: "showQRscan", sender: nil)
        //}
        //        else {
        //            let alert = UIAlertController(title: "Safety First", message: "You must be at the car wash to scan the QR Code.", preferredStyle: .alert)
        //            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
        //            }))
        //            self.present(alert, animated: true, completion: nil)
        //        }
    }
    
    
    @IBAction func btnCancelScanClicked(_ sender: AnyObject) {
        
        _ = navigationController?.popToRootViewController(animated: true)
    }
    
}
