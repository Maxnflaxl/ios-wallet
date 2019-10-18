//
// UnlockPasswordViewController.swift
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

class UnlockPasswordViewController: BaseViewController {
    enum UnlockEvent {
        case unlock
        case changePassword
        case seedPhrase
        case unlockSecurity
    }
    
    @IBOutlet private var passField: BMField!
    @IBOutlet private var titleLabel: UILabel!
    
    private var event: UnlockEvent!
    private var isUnlocked = false
    
    public var completion: ((Bool) -> Void)?
    
    init(event: UnlockEvent) {
        super.init(nibName: nil, bundle: nil)
        
        self.event = event
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    override var isUppercasedTitle: Bool {
        get {
            return true
        }
        set {
            super.isUppercasedTitle = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideKeyboardWhenTappedAround()
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: false)
        
        switch event {
        case .unlock:
            title = Localizable.shared.strings.your_password
            titleLabel.text = Localizable.shared.strings.unlock_password
        case .unlockSecurity:
            title = Localizable.shared.strings.your_password
            titleLabel.text = Localizable.shared.strings.enter_your_password
        case .changePassword:
            title = Localizable.shared.strings.change_password
        default:
            title = Localizable.shared.strings.show_seed_phrase
            titleLabel.text = Localizable.shared.strings.enter_your_password
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        _ = passField.becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        completion?(isUnlocked)
    }
    
    @IBAction func onLogin(sender: UIButton) {
        if passField.text?.isEmpty ?? true {
            passField.error = Localizable.shared.strings.empty_password
            passField.status = BMField.Status.error
        }
        else if let pass = passField.text {
            let valid = AppModel.sharedManager().isValidPassword(pass)
            if !valid {
                passField.error = Localizable.shared.strings.current_password_error
                passField.status = BMField.Status.error
            }
            else {
                isUnlocked = true
                
                if event == .seedPhrase, let seed = OnboardManager.shared.getSeed() {
                    let vc = SeedPhraseViewController(event: .display, words: seed.components(separatedBy: ";"))
                    vc.increaseSecutirty = true
                    if var viewControllers = self.navigationController?.viewControllers {
                        viewControllers[viewControllers.count - 1] = vc
                        navigationController?.setViewControllers(viewControllers, animated: true)
                    }
                }
                else if event == .unlock || event == .unlockSecurity {
                    if navigationController?.viewControllers.count == 1 {
                        dismiss(animated: true) {}
                    }
                    else {
                        back()
                    }
                }
                else {
                    let vc = CreateWalletPasswordViewController()
                    if var viewControllers = self.navigationController?.viewControllers {
                        viewControllers[viewControllers.count - 1] = vc
                        navigationController?.setViewControllers(viewControllers, animated: true)
                    }
                }
            }
        }
    }
}

// MARK: TextField Actions

extension UnlockPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
}
