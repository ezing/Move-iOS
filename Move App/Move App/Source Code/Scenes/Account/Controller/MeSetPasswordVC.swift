//
//  MeSetPasswordVC.swift
//  Move App
//
//  Created by Wuju Zheng on 2017/3/10.
//  Copyright © 2017年 TCL Com. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MeSetPasswordViewController: UIViewController {
    
    
    @IBOutlet weak var saveBun: UIBarButtonItem!
    @IBOutlet weak var oldTf: UITextField!
    @IBOutlet weak var newTf: UITextField!
    
    @IBOutlet weak var oldValid: UILabel!
    @IBOutlet weak var oldValidHeiCon: NSLayoutConstraint!
    @IBOutlet weak var newValid: UILabel!
    
    
    
    var disposeBag = DisposeBag()
    var viewModel: MeSetPasswordViewModel!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.validatedOld
            .drive(onNext: { result in
                switch result{
                case .failed(let message):
                    self.showOldError(message)
                default:
                    self.revertOldError()
                }
            })
            .addDisposableTo(disposeBag)
        
        viewModel.validatedNew
            .drive(onNext: { result in
                switch result{
                case .failed(let message):
                    self.showNewError(message)
                default:
                    self.revertNewError()
                }
            })
            .addDisposableTo(disposeBag)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        oldTf.resignFirstResponder()
        newTf.resignFirstResponder()
    }
    
    
    func showOldError(_ text: String) {
        oldValidHeiCon.constant = 16
        oldValid.isHidden = false
        oldValid.alpha = 0.0
        oldValid.text = text
        UIView.animate(withDuration: 0.6) { [weak self] in
            self?.oldValid.textColor = ValidationColors.errorColor
            self?.oldValid.alpha = 1.0
            self?.view.layoutIfNeeded()
        }
    }
    
    func revertOldError() {
        oldValidHeiCon.constant = 0
        oldValid.isHidden = true
        oldValid.alpha = 1.0
        oldValid.text = ""
        UIView.animate(withDuration: 0.6) { [weak self] in
            self?.oldValid.textColor = ValidationColors.okColor
            self?.oldValid.alpha = 0.0
            self?.view.layoutIfNeeded()
        }
    }
    
    func showNewError(_ text: String) {
        newValid.isHidden = false
        newValid.alpha = 0.0
        newValid.text = text
        UIView.animate(withDuration: 0.6) { [weak self] in
            self?.newValid.textColor = ValidationColors.errorColor
            self?.newValid.alpha = 1.0
            self?.view.layoutIfNeeded()
        }
    }
    
    func revertNewError() {
        newValid.isHidden = true
        newValid.alpha = 1.0
        newValid.text = ""
        UIView.animate(withDuration: 0.6) { [weak self] in
            self?.newValid.textColor = ValidationColors.okColor
            self?.newValid.alpha = 0.0
            self?.view.layoutIfNeeded()
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        oldValid.isHidden = true
        oldValidHeiCon.constant = 0
        newValid.isHidden = true
        
        
        viewModel = MeSetPasswordViewModel(
            input:(
                old: oldTf.rx.text.orEmpty.asDriver(),
                new: newTf.rx.text.orEmpty.asDriver(),
                saveTaps: saveBun.rx.tap.asDriver()
            ),
            dependency: (
                userManager: UserManager.shared,
                validation: DefaultValidation.shared,
                wireframe: DefaultWireframe.sharedInstance
        ))
        
        viewModel.saveEnabled
            .drive(onNext: { [unowned self] valid in
                self.saveBun.isEnabled = valid
                self.saveBun.tintColor?.withAlphaComponent(valid ? 1.0 : 0.5)
            })
            .addDisposableTo(disposeBag)
        
        
        
        viewModel.saveResult
            .drive(onNext: { [unowned self] result in
                self.oldTf.resignFirstResponder()
                self.newTf.resignFirstResponder()
                switch result {
                case .failed(let message):
                    self.showNewError(message)
                case .ok:
                    _ = self.navigationController?.popViewController(animated: true)
                default:
                    break
                }
            })
            .addDisposableTo(disposeBag)
    }
    
    
    
    
    
    
    
}