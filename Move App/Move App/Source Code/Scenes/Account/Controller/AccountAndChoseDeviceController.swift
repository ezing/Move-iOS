//
//  AccountAndChoseDeviceController.swift
//  Move App
//
//  Created by Vernon yellow on 17/2/21.
//  Copyright © 2017年 TCL Com. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import RxOptional


class AccountAndChoseDeviceController: UIViewController, UITableViewDelegate {

    @IBOutlet weak var headOutlet: UIImageView!
    @IBOutlet weak var accountNameOutlet: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel: AccountAndChoseDeviceViewModel!
    
    let disposeBag = DisposeBag()
    let enterCount = Variable(0)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        let selectedDeviceInfo = tableView.rx.itemSelected.asObservable()
            .map({ self.viewModel.devices?[$0.row] })
            .filterNil()
        
        viewModel = AccountAndChoseDeviceViewModel(
            input: (
                enterCount: enterCount.asObservable(),
                selectedDeviceInfo: selectedDeviceInfo
            ),
            dependency:(
                userManager: UserManager.shared,
                deviceManager: DeviceManager.shared,
                wireframe: DefaultWireframe.sharedInstance
            )
        )
        
        viewModel.head
            .drive(onNext: { [weak self] in
                self?.headOutlet.imageFromURL($0, placeholder: R.image.member_btn_contact_nor()!)
            })
            .addDisposableTo(disposeBag)
        
        viewModel.accountName
            .drive(accountNameOutlet.rx.text)
            .addDisposableTo(disposeBag)
        
      
        tableView.rx
            .setDelegate(self)
            .addDisposableTo(disposeBag)
        
        viewModel.cellDatas?
            .bindTo(tableView.rx.items(cellIdentifier: R.reuseIdentifier.cellDevice.identifier, cellType: UITableViewCell.self)){ (row, element, cell) in
                cell.textLabel?.text = element.devType
                cell.detailTextLabel?.text = element.name
                cell.imageView?.imageFromURL(element.iconUrl!, placeholder:  R.image.member_btn_contact_nor()!)
            }
            .addDisposableTo(disposeBag)
        
        viewModel.selected
            .drive(onNext: { [weak self] in
                let vc = R.storyboard.account.accountKidsRulesuserController()!
                self?.navigationController?.show(vc, sender: nil)
            })
            .addDisposableTo(disposeBag)
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enterCount.value += 1
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    
    // to prevent swipe to delete behavior
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let cell = tableView.cellForRow(at: indexPath)
//        cell?.selectionStyle = UITableViewCellSelectionStyle.none
//        let vc = R.storyboard.account.accountKidsRulesuserController()!
//        DeviceManager.shared.currentDevice = viewModel.devices?[indexPath.row]
//        self.navigationController?.show(vc, sender: nil)
//    }
    
}