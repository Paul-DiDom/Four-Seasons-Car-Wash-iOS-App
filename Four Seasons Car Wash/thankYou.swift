import UIKit
import AudioToolbox

class thankYou: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        AccountBalanceStore.markRefreshRequired()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
