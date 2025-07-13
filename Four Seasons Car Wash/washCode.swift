import UIKit

class washCode: UIViewController {
    
    @IBOutlet var btnCoinbayCode: UIButton!
    @IBOutlet var btnVacuumsCode: UIButton!
    @IBOutlet var btnTouchlessCode: UIButton!
    @IBOutlet var myStackView: UIStackView!
    var site = 0
    @IBOutlet weak var homeIcon: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        ViewController.fixButton(btnCoinbayCode)
        ViewController.fixButton(btnVacuumsCode)
        ViewController.fixButton(btnTouchlessCode)
        site = getSite()
        if (site == 3 || site == 4 ) {
            btnTouchlessCode.isHidden = false
            myStackView.spacing = 30
        }
        else {
            btnTouchlessCode.isHidden = true
            myStackView.spacing = 60
        }
    }
    // "car", "drop", "car.top.door.front.left.open"
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        btnCoinbayCode.setImage(UIImage(systemName: "drop"), for: .normal)
        btnVacuumsCode.setImage(UIImage(systemName: "car.top.door.front.left.open"), for: .normal)
        btnTouchlessCode.setImage(UIImage(systemName: "car"), for: .normal)
        homeIcon.layer.cornerRadius = 10
        homeIcon.clipsToBounds = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func btnCodeCoinbayClicked(_ sender: AnyObject) {
        if (site == 1) {
            performSegue(withIdentifier: "showCoinBayCode", sender: nil)
        }
        else if (site == 2) {
            performSegue(withIdentifier: "showCoinBayCode2", sender: nil)
        }
        else if (site == 3) {
            performSegue(withIdentifier: "showCoinBayCode3", sender: nil)
        }
        else if (site == 4) {
            performSegue(withIdentifier: "showCoinBayCode4", sender: nil)
        }
    }
    
    @IBAction func btnCodeVacuumClicked(_ sender: AnyObject) {
        if (site == 1) {
            performSegue(withIdentifier: "showVacuumCode", sender: nil)
        }
        else if (site == 2) {
            performSegue(withIdentifier: "showVacuumCode2", sender: nil)
        }
        else if (site == 3) {
            performSegue(withIdentifier: "showVacuumCode3", sender: nil)
        }
        else if (site == 4) {
            performSegue(withIdentifier: "showVacuumCode4", sender: nil)
        }
    }
    
    
    @IBAction func btnAutomaticCodeClicked(_ sender: Any) {
        if (site == 3) {
            performSegue(withIdentifier: "showAutomaticAcode", sender: nil)
        }
        else if (site == 4) {
            performSegue(withIdentifier: "showAutomaticLcode", sender: nil)
        }
    }
    
}
