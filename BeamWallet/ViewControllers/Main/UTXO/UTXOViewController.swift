//
//  UTXOViewController.swift
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

class UTXOViewController: BaseViewController {
    enum UTXOSelectedState {
        case active
        case all
    }
    
    private var selectedState: UTXOSelectedState = .active
    private var utxos = [BMUTXO]()
    private var expandBlock = true

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private var headerView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "UTXO"
        
        tableView.register(UTXOCell.self)
        tableView.register(UTXOBlockCell.self)

        filterUTXOS()
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    private func filterUTXOS() {
        if selectedState == .all {
            if let utox = AppModel.sharedManager().utxos {
                self.utxos = utox as! [BMUTXO]
            }
        }
        else{
            if let utxos = AppModel.sharedManager().utxos {
                self.utxos = utxos as! [BMUTXO]
                self.utxos = self.utxos.filter { $0.status == 1 || $0.status == 2 }
            }
        }
    }
    
    @IBAction func onStatus(sender : UISegmentedControl) {
        if sender.selectedSegmentIndex == 1 {
            onClickAll()
        }
        else{
            onClickActive()
        }
    }
}

extension UTXOViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 55
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 && indexPath.section == 0{
            return expandBlock ? 156 : 106
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension UTXOViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return utxos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView
                .dequeueReusableCell(withType: UTXOBlockCell.self, for: indexPath)
            cell.configure(with: (status: AppModel.sharedManager().walletStatus, expand: expandBlock))
            cell.delegate = self
            return cell
        }
        else{
            let cell = tableView
                .dequeueReusableCell(withType: UTXOCell.self, for: indexPath)
                .configured(with: (row: indexPath.row, utxo: utxos[indexPath.row]))
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return nil
        }
        
        return headerView
    }
}

extension UTXOViewController : UTXOBlockCellDelegate {
    func onClickAll() {
        selectedState = .all
        
        filterUTXOS()

        tableView.reloadData()
        tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }
    
    func onClickActive() {
        selectedState = .active
        
        filterUTXOS()

        tableView.reloadData()
        tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }
    
    func onClickExpand() {
        expandBlock = !expandBlock
        
        self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
    }
}

extension UTXOViewController : WalletModelDelegate {
    func onReceivedUTXOs(_ utxos: [BMUTXO]) {
        DispatchQueue.main.async {
            if let utox = AppModel.sharedManager().utxos {
                self.utxos = utox as! [BMUTXO]
                
                if self.selectedState == .active {
                    self.utxos = self.utxos.filter { $0.status == 1 || $0.status == 2 }
                }
            }
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
    
    func onWalletStatusChange(_ status: BMWalletStatus) {
        DispatchQueue.main.async {
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
}


