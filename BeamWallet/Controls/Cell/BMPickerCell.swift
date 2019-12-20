//
// BMPickerCell.swift
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


class BMPickerCell: BaseCell {
    
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var detailLabel: UILabel!
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var arrowView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        mainView.backgroundColor = UIColor.main.cellBackgroundColor
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.main.selectedColor
        self.selectedBackgroundView = selectedView
        
        arrowView.image = Tick()?.withRenderingMode(.alwaysTemplate)
        arrowView.tintColor = UIColor.main.brightTeal
        detailLabel.textColor = UIColor.main.blueyGrey
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        mainView.backgroundColor = highlighted ? UIColor.main.selectedColor : UIColor.main.cellBackgroundColor
    }
    
    func configure(data:BMPickerData) {
        titleLabel.text = data.title
        detailLabel.isHidden = data.detail == nil
        detailLabel.text = data.detail
        
        if let color = data.titleColor {
            titleLabel.textColor = color
        }
        
        if data.multiplie {
            arrowView.image = (data.arrowType == BMPickerData.ArrowType.selected) ? CheckboxFull() : CheckboxEmptyNew()
        }
        else{
            arrowView.isHidden = data.arrowType != BMPickerData.ArrowType.selected
        }
    }
}
