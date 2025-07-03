import UIKit
import AVFoundation

class WashCode_QR_scan: UIViewController , AVCaptureMetadataOutputObjectsDelegate{
    
    @IBOutlet var btnToggleLight: UIButton!
    
    var captureSession = AVCaptureSession()
    var videoPreviewLayer = AVCaptureVideoPreviewLayer()
    var qrCodeFrameView: UIView?
    private let supportedCodeTypes = [AVMetadataObject.ObjectType.qr]
    var washCode = ""
    var x = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        if (UserDefaults.standard.object(forKey: "washCode") != nil)
        {
            washCode = UserDefaults.standard.object(forKey: "washCode") as! String
        }
        
        // Do any additional setup after loading the view.
        // Get the back-facing camera for capturing videos
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
        
        guard let captureDevice = deviceDiscoverySession.devices.first else {
            print("Failed to get the camera device")
            return
        }
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Set the input device on the capture session.
            captureSession.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
            //captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
        
        // According to Apple's documentation, the queue must be a serial queue. DispatchQueue.main is the default serial queue.
        
        // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        //videoPreviewLayer.frame = view.layer.bounds  // will fill the whole screen
        
        videoPreviewLayer.frame = CGRect(x: 0, y: 200, width: 400, height: 300) // only my rectangle
        
        self.view.layer.addSublayer(videoPreviewLayer)
        
        // Start video capture.
        captureSession.startRunning()
        
        ViewController.fixButton(btnToggleLight)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        var washChosen = false
        if (UserDefaults.standard.object(forKey: "washCodeChosen") != nil)
        {
            washChosen = UserDefaults.standard.object(forKey: "washCodeChosen") as! Bool
        }
        if (washChosen == false) {
            self.performSegue(withIdentifier: "showHome", sender: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            //messageLabel.text = "No QR code is detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                
                if(metadataObj.stringValue == "tech1stautoteller" && x == 0) {
                    x = 1
                    UserDefaults.standard.set(false, forKey: "washCodeChosen")
                    captureSession.stopRunning()
                    let site = getSite()
                    var wash = "AWASH0"
                    if (site == 4) {
                        wash = "LWASH0"
                    }
                    self.startRequest(type: "wc", deviceChosen: wash, amountChosen:"0", code:washCode, equip: "6")
                }
            }
        }
    }
    
    @IBAction func toggleLight(_ sender: Any) {
        let avDevice = AVCaptureDevice.default(for: AVMediaType.video)
        if (avDevice?.hasTorch)! {
            do {
                try avDevice?.lockForConfiguration()
            } catch {
                
            }
            
            if (avDevice?.isTorchActive)! {
                avDevice?.torchMode = AVCaptureDevice.TorchMode.off
            } else {
                
                do {
                    try avDevice?.setTorchModeOn(level: 1.0)
                } catch {
                    
                }
            }
            avDevice?.unlockForConfiguration()
        }
    }

}
