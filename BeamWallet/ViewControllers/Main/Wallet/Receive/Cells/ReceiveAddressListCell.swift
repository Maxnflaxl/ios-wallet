//
// ReceiveAddressListCell.swift
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

class ReceiveAddressListCell: BaseCell {

    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var idLabel: UILabel!
    @IBOutlet weak private var categoryLabel: UILabel!
    
    @IBOutlet weak private var categoryWidth: NSLayoutConstraint!

    @IBOutlet weak private var transactionCommentIcon: UIImageView!
    @IBOutlet weak private var transactionCommentLabel: UILabel!
    @IBOutlet weak private var transactionCommentDate: UILabel!

    @IBOutlet weak private var transactionCommentIconY: NSLayoutConstraint!
    @IBOutlet weak private var transactionCommentLabelY: NSLayoutConstraint!
    @IBOutlet weak private var transactionCommentDateY: NSLayoutConstraint!
    
    @IBOutlet weak private var transactionCommentIconHeight: NSLayoutConstraint!
    @IBOutlet weak private var transactionCommentIconWidth: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        self.selectedBackgroundView = selectedView
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    public func setItalic(autoGenerated:Bool, italic:Bool)
    {
        if (italic || autoGenerated)
        {
            nameLabel.font = ItalicFont(size: 17)
            if autoGenerated {
                nameLabel.text = Localizables.shared.strings.autogenerated
            }
        }
        else{
            nameLabel.font = RegularFont(size: 17)
        }
    }
}

extension ReceiveAddressListCell: Configurable {
    
    func configure(with options: (row: Int, address:BMAddress)) {
        
        mainView.backgroundColor = (options.row % 2 == 0) ? UIColor.main.marineTwo : UIColor.main.marine
        
        backgroundColor = mainView.backgroundColor
        
        if let category = AppModel.sharedManager().findCategory(byId: options.address.category) {
            categoryLabel.textColor = UIColor.init(hexString: category.color)
            categoryLabel.text = category.name
            
            let aString:NSString = category.name as NSString
            
            let rectNeeded = aString.boundingRect(with: CGSize(width: 9999, height: 20), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: categoryLabel.font!], context: nil)
            
            categoryWidth.constant = rectNeeded.width + 10
        }
        else{
            categoryLabel.text = String.empty()
            categoryWidth.constant = 10
        }
        
        if options.address.label.isEmpty {
            nameLabel.text = Localizables.shared.strings.no_name
        }
        else{
            nameLabel.text = options.address.label
        }
        
        idLabel.text = options.address.walletId

        transactionCommentIcon.image = nil
        transactionCommentLabel.text = nil
        transactionCommentDate.text = nil
        
        transactionCommentIconY.constant = 0
        transactionCommentLabelY.constant = 0
        transactionCommentDateY.constant = 0
        
        transactionCommentIconHeight.constant = 0
        transactionCommentIconWidth.constant = 0
        
        if let last = AppModel.sharedManager().lastTransaction(fromAddress: options.address.walletId)
        {
            transactionCommentIconY.constant = 10
            transactionCommentLabelY.constant = 10
            transactionCommentDateY.constant = 10
            
            transactionCommentIconHeight.constant = 16
            transactionCommentIconWidth.constant = 16
            
            if !last.comment.isEmpty {
                transactionCommentIcon.image = IconComment()
                transactionCommentLabel.text =  "”" + last.comment + "”"
            }
            
            transactionCommentDate.text = last.shortDate()
        }
    }
}
