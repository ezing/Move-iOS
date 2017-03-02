//
//  LanguageViewController.swift
//  Move App
//
//  Created by xiaohui on 17/3/1.
//  Copyright © 2017年 TCL Com. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import RxOptional

class LanguageViewController: UIViewController {
    
    
    @IBOutlet weak var tableview: UITableView!
    
    var currentVariable = Variable("aL")
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let selected = tableview.rx.itemSelected.asDriver()
            .map({ self.tableview.cellForRow(at: $0)?.textLabel?.text })
            .filterNil()
        selected.drive(currentVariable)
            .addDisposableTo(disposeBag)
        
        let save = selected.map({_ in Void() })
        
        let viewModel = LanguageViewModel(
            input: (
                language: selected,
                save: save
            ),
            dependency: (
                settingsManager: WatchSettingsManager.share,
                validation: DefaultValidation.shared,
                wireframe: DefaultWireframe.sharedInstance
            )
        )
        
        let data = viewModel.lauguages  //Observable.just(itemStringArr)
        let current = currentVariable.asDriver()
        let cellData = Driver.combineLatest(data, current) { data, current in data.map({ ($0, current) }) }
        
        cellData.drive(tableview.rx.items(cellIdentifier: R.reuseIdentifier.cellLanguage.identifier)) { index, model, cell in
            cell.textLabel?.text = model.0
            cell.accessoryType = (model.0 != model.1) ? .none : .checkmark
            cell.selectionStyle = .none
        }.addDisposableTo(disposeBag)
        
    }

}
