//
//  RelationshipTableController.swift
//  Move App
//
//  Created by Vernon yellow on 17/2/14.
//  Copyright © 2017年 TCL Com. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class RelationshipTableController: UITableViewController {
    
    var relationBlock: ((Relation) -> ())?
    
    @IBOutlet var cells: [UITableViewCell]!
    
    var deviceAddInfo: DeviceBindInfo?
    
    var disposeBag = DisposeBag()
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        self.BaseSetting()
    }
    
    
    private func BaseSetting(){
        
        tableView.contentInset = UIEdgeInsetsMake(-34, 0, 0, 0)
        for cell in cells {
            cell.selectionStyle = UITableViewCellSelectionStyle.none
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        for cell in cells {
            if cell == tableView.cellForRow(at: indexPath) {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            }else{
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
        }
        
        var identity: Relation?
        if indexPath.row < 8 {
            identity = Relation(input: String(indexPath.row + 1))
        }else{
            identity = Relation.other(value: "Other")
        }
        
        if self.relationBlock != nil {
            self.relationBlock!(identity!)
            _ = self.navigationController?.popViewController(animated: true)
            return
        }
        
        deviceAddInfo?.identity = identity
        
        if deviceAddInfo?.isMaster == true {
            self.performSegue(withIdentifier: R.segue.relationshipTableController.showKidInformation, sender: nil)
        }else{
            DeviceManager.shared.joinGroup(joinInfo: deviceAddInfo!)
                .subscribe(onNext: {[weak self] flag in
                    _ = self?.navigationController?.popToRootViewController(animated: true)
                }, onError: { er in
                    print(er)
                    if let msg = errorRecover(er) {
                        self.showMessage(msg)
                    }
                })
                .addDisposableTo(disposeBag)
        }
    }
    
    func showMessage(_ text: String) {
        let vc = UIAlertController(title: nil, message: text, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel)
        vc.addAction(action)
        self.present(vc, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let sg = R.segue.relationshipTableController.showKidInformation(segue: segue) {
            sg.destination.addInfoVariable.value = self.deviceAddInfo!
            sg.destination.isForSetting = false
        }
    }
    
}


fileprivate func errorRecover(_ error: Error) -> String? {
    guard let _error = error as?  WorkerError else {
        return nil
    }
    
    if WorkerError.webApi(id: 7, field: "uid", msg: "Exists") == _error {
        return "This watch is existed"
    }
    
    let msg = WorkerError.apiErrorTransform(from: _error)
    return msg
}















