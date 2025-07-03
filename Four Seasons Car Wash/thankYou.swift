import UIKit
import AudioToolbox

class thankYou: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        UserDefaults.standard.set(true, forKey: "checkBalance")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
