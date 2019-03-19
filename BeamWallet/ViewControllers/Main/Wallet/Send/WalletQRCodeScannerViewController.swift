//
//  WalletQRCodeScannerViewController.swift
//  BeamWallet
//
// Copyright 2018 Beam Development
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//


import UIKit
import AVFoundation
import Loaf

protocol WalletQRCodeScannerViewControllerDelegate: AnyObject {
    func didScanQRCode(value:String)
}

class WalletQRCodeScannerViewController: BaseViewController {

    weak var delegate: WalletQRCodeScannerViewControllerDelegate?
    
    @IBOutlet private weak var scannerView: UIView!

    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!

    var offset:CGFloat = 180
    var scannedValue:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Scan QR code"
        
        if Device.screenType == .iPhones_6_6s_7_8 || Device.screenType == .iPhones_5_5s_5c_SE
            || Device.screenType == .iPhones_6Plus_6sPlus_7Plus_8Plus
        {
           offset = 140
        }
        
        scannerView.frame = CGRect(x: 0, y: offset, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height-offset)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        checkCameraPermissions()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    private func initSession() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, .qr, .aztec, .code128]
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = scannerView.bounds
        previewLayer.videoGravity = .resizeAspectFill
        scannerView.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }

}

//MARK: - V3QRCodeReaderDelegate

extension WalletQRCodeScannerViewController : AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            getBarCodeData(code: stringValue)
        }

    }
    
    func getBarCodeData(code: String) {
        if (scannedValue.isEmpty)
        {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

            scannedValue = code;
            
            if (!AppModel.sharedManager().isValidAddress(code))
            {
                let loaf = Loaf("QR code cannot be recognized recognized. Please try again.", state: .custom(.init(backgroundColor: UIColor.black.withAlphaComponent(0.8), icon: nil)), sender: self)
                loaf.show(.average) {
                    self.scannedValue = ""
                }
            }
            else{
                navigationController?.popViewController(animated: true)
                
                delegate?.didScanQRCode(value: code)
            }
        }

    }
}


//MARK: - Permissions

extension WalletQRCodeScannerViewController {
    
    private func checkCameraPermissions() {
        let authStatus =  AVCaptureDevice.authorizationStatus(for: .video)
        
        if(authStatus == .authorized) {
            initSession()
        }
        else if(authStatus == .notDetermined) {

            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                DispatchQueue.main.async {
                    if granted {
                        self.initSession()
                    }
                    else{
                        self.camDenied()
                    }
                }
            }
        }
        else if (authStatus == .restricted) {
            self.alert(message: "You've been restricted from using the camera on this device. Without camera access this feature won't work. Please contact the device owner so they can give you access")
        }
        else {
            self.camDenied()
        }
    }
    
    private func camDenied() {
        let message = "It looks like your privacy settings are preventing us from accessing your camera to do qr code scanning. You can fix this by doing the following:\n\n1. Touch the Go button below to open the Settings app.\n\n2. Turn the Camera on.\n\n3. Open this app and try again."
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        let openAction = UIAlertAction(title: "Open Settings", style: .default) { (action) in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: { (_ ) in
                 self.navigationController?.popViewController(animated: true)
            })
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            self.navigationController?.popViewController(animated: true)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(openAction)

        self.present(alertController, animated: true, completion: nil)
    }
}


