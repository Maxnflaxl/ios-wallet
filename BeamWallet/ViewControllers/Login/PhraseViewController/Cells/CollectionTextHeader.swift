//
//  CollectionTextHeader.swift
//  BeamWallet
//
//  Created by Denis on 10/18/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class CollectionTextHeader: UICollectionReusableView {
    static let reuseIdentifier = "CollectionTextHeader"
    static let nib = "CollectionTextHeader"
    
    @IBOutlet private weak var textLabel: UILabel!

    public func setData(event:SeedPhraseViewController.EventType) {
        switch event {
        case .display:
            textLabel.text = Localizable.shared.strings.display_seed
        case .confirm:
            textLabel.text = Localizable.shared.strings.confirm_seed_text
        case .restore:
            textLabel.text = Localizable.shared.strings.input_seed
        }
    }
}
