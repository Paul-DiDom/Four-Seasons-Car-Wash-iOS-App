import UIKit
import WebKit

class PayPal: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        self.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.isLoading), options: .new, context: nil)
        
        activityIndicator.style = .large
        activityIndicator.color = .black
        activityIndicator.startAnimating()
        activityIndicator.hidesWhenStopped = true
        var id = ""
        if (UserDefaults.standard.object(forKey: "userId") != nil)
        {
            id = UserDefaults.standard.object(forKey: "userId") as! String
        }
        
        let url = URL (string:"https://tech1app.com/fourseasons/default.aspx?userID=" + id)
        let request = URLRequest(url: url!)
        webView.load(request)
        UserDefaults.standard.set(true, forKey: "checkBalance")
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "loading" {
            if webView.isLoading {
                activityIndicator.startAnimating()
                activityIndicator.isHidden = false
            } else {
                activityIndicator.stopAnimating()
            }
        }
    }
    
}
