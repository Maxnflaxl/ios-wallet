//
// CreateWalletProgressViewController.swift
// BeamWallet
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

class CreateWalletProgressViewController: BaseViewController {

    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var progressTitleLabel: UILabel!
    @IBOutlet private weak var progressValueLabel: UILabel!
    @IBOutlet private weak var restotingInfoLabel: UILabel!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var logoYOffset: NSLayoutConstraint!
    @IBOutlet private weak var stackYOffset: NSLayoutConstraint!

    private var timeoutTimer:Timer?
    
    private var password:String?
    private var phrase:String?
    private var isPresented = false
    private var start = Date.timeIntervalSinceReferenceDate;

    init(password:String, phrase:String?) {
        super.init(nibName: nil, bundle: nil)

        self.password = password
        self.phrase = phrase
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizables.shared.strings.fatalInitCoderError)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        removeLeftButton()
        
        let progressViewHeight: CGFloat = 4.0
        
        let transformScale = CGAffineTransform(scaleX: 1.0, y: progressViewHeight)
        progressView.transform = transformScale
        
        if AppModel.sharedManager().isRestoreFlow {
            progressTitleLabel.text = Localizables.shared.strings.restoring_wallet
            restotingInfoLabel.isHidden = false
            progressValueLabel.text = Localizables.shared.strings.restored + "0%"
            progressValueLabel.isHidden = false
            cancelButton.isHidden = false
        }
        else if phrase == nil {
            timeoutTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(onTimeOut), userInfo: nil, repeats: false)
            
            progressTitleLabel.text = Localizables.shared.strings.loading_wallet
            cancelButton.isHidden = true
        }
        
        if Device.screenType == .iPhones_5 {
            logoYOffset.constant = 50
            stackYOffset.constant = 50
        }
        else if Device.screenType == .iPhones_6 {
        //    logoYOffset.constant = 50
         //   stackYOffset.constant = 50
        }
        
        AppModel.sharedManager().addDelegate(self)

        startCreateWallet()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        timeoutTimer?.invalidate()
        
        if isMovingFromParent {
            AppModel.sharedManager().removeDelegate(self)
        }
    }
    
    private func openMainPage() {
        timeoutTimer?.invalidate()
        
        AppModel.sharedManager().removeDelegate(self)
        
        AppModel.sharedManager().refreshAddresses()
        
        let mainVC = BaseNavigationController.navigationController(rootViewController: WalletViewController())
        let menuViewController = LeftMenuViewController()
        
        let sideMenuController = LGSideMenuController(rootViewController: mainVC,
                                                      leftViewController: menuViewController,
                                                      rightViewController: nil)
        
        sideMenuController.leftViewWidth = UIScreen.main.bounds.size.width - 60;
        sideMenuController.leftViewPresentationStyle = .slideAbove;
        sideMenuController.rootViewLayerShadowRadius = 0
        sideMenuController.rootViewLayerShadowColor = UIColor.clear
        sideMenuController.leftViewLayerShadowRadius = 0
        sideMenuController.rootViewCoverAlphaForLeftView = 0.5
        sideMenuController.rootViewCoverAlphaForRightView = 0.5
        sideMenuController.leftViewCoverAlpha = 0.5
        sideMenuController.rightViewCoverAlpha = 0.5
        sideMenuController.modalTransitionStyle = .crossDissolve
        
        self.navigationController?.setViewControllers([sideMenuController], animated: true)
    }

    private func startCreateWallet() {
        
        if !AppModel.sharedManager().isInternetAvailable {
            AppModel.sharedManager().resetWallet(false)

            self.navigationController?.popViewController(animated: true)

            self.alert(title: Localizables.shared.strings.error, message: Localizables.shared.strings.no_internet) { (_ ) in

            }
        }
        else{
            if let phrase = phrase, AppModel.sharedManager().isRestoreFlow
            {
                let created = AppModel.sharedManager().createWallet(phrase, pass: password!)
                if(!created)
                {
                    self.alert(title: Localizables.shared.strings.error, message: Localizables.shared.strings.wallet_not_created) { (_ ) in
                        if AppModel.sharedManager().isInternetAvailable {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                        else{
                            DispatchQueue.main.async {
                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                    }
                }
                else{
                    RestoreManager.shared.startRestore(completion: { (completed) in
                        if completed {
                            DispatchQueue.main.async {
                                self.restoreCompleted()
                            }
                        }
                    }) { (error, progress) in
                        DispatchQueue.main.async {
                            if let reason = error {
                                self.alert(title: Localizables.shared.strings.error, message: reason.localizedDescription) { (_ ) in
                                    AppModel.sharedManager().isRestoreFlow = false
                                    self.navigationController?.popToRootViewController(animated: true)
                                }
                            }
                            else if let percent = progress {
                                self.progressView.progress = percent
                                self.progressValueLabel.text = Localizables.shared.strings.restored + "\(Int32(percent * 100))%"
                            }
                        }
                    }
                }
            }
            else if let phrase = phrase {
                let created = AppModel.sharedManager().createWallet(phrase, pass: password!)
                if(!created)
                {
                    self.alert(title: Localizables.shared.strings.error, message: Localizables.shared.strings.wallet_not_created) { (_ ) in
                        if AppModel.sharedManager().isInternetAvailable {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                        else{
                            DispatchQueue.main.async {
                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                    }
                }
            }
            else{
                let opened = AppModel.sharedManager().openWallet(password!)
                if(!opened)
                {
                    self.alert(title: Localizables.shared.strings.error, message: Localizables.shared.strings.wallet_not_opened) { (_ ) in
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
                else{
                    UIView.animate(withDuration: 0.3) {
                        self.progressView.progress = 0.2
                    }
                }
            }
        }
    }
    
    private func restoreCompleted() {
      //  DispatchQueue.global(qos: .background).async {
        AppModel.sharedManager().restore()
        AppModel.sharedManager().isRestoreFlow = false
        self.startCreateWallet()
       // }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func openNodeController() {
        let vc = EnterNodeAddressViewController()
        vc.completion = { [weak self]
            obj in
            
            if obj == true {
                AppModel.sharedManager().isConnecting = false
                
                self?.timeoutTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self as Any, selector: #selector(self?.onTimeOut), userInfo: nil, repeats: false)
                
                self?.startCreateWallet()
            }
            else{
                self?.navigationController?.popToRootViewController(animated: true)
            }
        }
        vc.hidesBottomBarWhenPushed = true
        self.pushViewController(vc: vc)
    }

// MARK: IBAction
    
    @IBAction func onCancel(sender :UIButton) {
        if AppModel.sharedManager().isRestoreFlow {
            RestoreManager.shared.cancelRestore()
            AppModel.sharedManager().isRestoreFlow = false
        }
        
        let appModel = AppModel.sharedManager()
        appModel.resetWallet(true)
        
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc private func onTimeOut() {
        if Settings.sharedManager().isChangedNode() {
            if !self.isPresented {
                self.isPresented = true
                
                self.openMainPage()
            }
        }
    }
}

extension CreateWalletProgressViewController : WalletModelDelegate {
    
    func onSyncProgressUpdated(_ done: Int32, total: Int32) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }

            if AppModel.sharedManager().isRestoreFlow {
                if total > 0 {
                    let speed = Double(done) / Double((Date.timeIntervalSinceReferenceDate - strongSelf.start))
                   
                    if speed > 0 {
                        let sizeLeft = Double(total-done)
                        let timeLeft = sizeLeft / speed
                        
                        print("-----------")
                        print(timeLeft.asTime(style: .abbreviated))
                        print("-----------")
                    }
    
                    let progress: Float = Float(done) / Float(total)
                    let percent = Int32(progress * 100)
                    
                    strongSelf.progressValueLabel.text = Localizables.shared.strings.restored + "\(percent)%"
                }
            }
            
            if total == done && !strongSelf.isPresented && !AppModel.sharedManager().isRestoreFlow {
                strongSelf.isPresented = true
                strongSelf.progressView.progress = 1
                strongSelf.openMainPage()
            }
            else{
                strongSelf.progressView.progress = Float(Float(done)/Float(total))
            }
        }
    }
    
    func onWalletError(_ _error: Error) {
        DispatchQueue.main.async {
            [weak self] in
            guard let strongSelf = self else { return }
            
            let error = _error as NSError
            
            if error.code == 2 && Settings.sharedManager().isChangedNode() {
                if !strongSelf.isPresented {
                    strongSelf.isPresented = true
                    
                    strongSelf.openMainPage()
                }
            }
            else if error.code == 1 {
                
                strongSelf.confirmAlert(title: Localizables.shared.strings.incompatible_node_title, message: Localizables.shared.strings.incompatible_node_info, cancelTitle: Localizables.shared.strings.cancel, confirmTitle: Localizables.shared.strings.change_settings, cancelHandler: { (_ ) in
                    
                    AppModel.sharedManager().resetWallet(false)
                    strongSelf.navigationController?.popViewController(animated: true)
                    
                }, confirmHandler: { (_ ) in
                    
                    strongSelf.openNodeController()
                })
            }
            else{
                if let controllers = strongSelf.navigationController?.viewControllers {
                    for vc in controllers {
                        if vc is EnterNodeAddressViewController {
                            return
                        }
                    }
                }
                strongSelf.alert(title: Localizables.shared.strings.error, message: error.localizedDescription, handler: { (_ ) in
                    AppModel.sharedManager().resetWallet(false)
                    strongSelf.navigationController?.popViewController(animated: true)
                })
            }
        }
    }
    
    func onLocalNodeStarted() {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            
            if !strongSelf.isPresented {
                strongSelf.isPresented = true
                
                strongSelf.openMainPage()
            }
        }
    }
}
