//
// ReceiveAmountCell.swift
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

class ReceiveAmountCell: BaseCell {
    
    weak var delegate: ReceiveCellProtocol?

    @IBOutlet weak private var textField: BMField!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
      //  contentView.backgroundColor = UIColor.main.marineTwo.withAlphaComponent(0.2)
    }
}

extension ReceiveAmountCell: Configurable {
    
    func configure(with amount: String?) {
        textField.text = amount
    }
}

extension ReceiveAmountCell : UITextFieldDelegate {
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        self.delegate?.textValueDidReturn?(self)
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.delegate?.textValueDidBegin?(self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let textFieldText: NSString = (textField.text ?? String.empty()) as NSString
        
        let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string).replacingOccurrences(of: String.coma(), with: String.dot())
        
        if txtAfterUpdate.isCorrectAmount() {
            textField.text = txtAfterUpdate
            self.delegate?.textValueDidChange?(self, txtAfterUpdate)
        }
        
        return false
    }
}

