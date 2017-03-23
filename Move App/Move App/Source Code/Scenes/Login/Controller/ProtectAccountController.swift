//
//  ProtectAccountController.swift
//  Move App
//
//  Created by Vernon yellow on 17/2/11.
//  Copyright © 2017年 TCL Com. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa


class ProtectAccountController: UIViewController {
    
    @IBOutlet weak var HelpLabel: UILabel!
    @IBOutlet weak var vcodeTf: UITextField!
    @IBOutlet weak var sendBun: UIButton!
    @IBOutlet weak var vcodeValidation: UILabel!
    @IBOutlet weak var doneBun: UIButton!
    
    var registerInfo: MoveApi.RegisterInfo?
    
    var viewModel: ProtectAccountViewModel!
    var disposeBag = DisposeBag()

    var timeCount = 0
    var timer: Timer?
    
    
    func showValidateError(_ text: String) {
        vcodeValidation.isHidden = false
        vcodeValidation.alpha = 0.0
        vcodeValidation.text = text
        UIView.animate(withDuration: 0.6) { [weak self] in
            self?.vcodeValidation.textColor = ValidationColors.errorColor
            self?.vcodeValidation.alpha = 1.0
            self?.view.layoutIfNeeded()
        }
    }
    
    func revertValidateError() {
        vcodeValidation.isHidden = true
        vcodeValidation.alpha = 1.0
        vcodeValidation.text = ""
        UIView.animate(withDuration: 0.6) { [weak self] in
            self?.vcodeValidation.textColor = ValidationColors.okColor
            self?.vcodeValidation.alpha = 0.0
            self?.view.layoutIfNeeded()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if  self.timer != nil {
            self.timer?.invalidate()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        HelpLabel.text = "Help us protect your.The verification\ncode was sent to your Email\n\(registerInfo?.email)."
        
        vcodeValidation.isHidden = true
        
        viewModel = ProtectAccountViewModel(
            input:(
                registerInfo: registerInfo!,
                vcode: vcodeTf.rx.text.orEmpty.asDriver(),
                sendTaps: sendBun.rx.tap.asDriver(),
                doneTaps: doneBun.rx.tap.asDriver()
            ),
            dependency: (
                userManager: UserManager.shared,
                validation: DefaultValidation.shared,
                wireframe: DefaultWireframe.sharedInstance
            )
        )
    
        
        viewModel.sendEnabled?
            .drive(onNext: { [unowned self] valid in
                self.sendBun.isEnabled = valid
                self.sendBun.alpha = valid ? 1.0 : 0.5
                if valid {
                    self.sendBun.setTitle("Resend", for: UIControlState.normal)
                }else{
                    self.timeCount = 90
                    self.sendBun.setTitle("Resend(\(self.timeCount)s)", for: UIControlState.normal)
                    self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.setupSendBunTitle), userInfo: nil, repeats: true)
                }
            })
            .addDisposableTo(disposeBag)
        
        viewModel.doneEnabled?
            .drive(onNext: { [weak self] valid in
                self?.doneBun.isEnabled = valid
                self?.doneBun.alpha = valid ? 1.0 : 0.5
            })
            .addDisposableTo(disposeBag)
        
        viewModel.sendResult?
            .drive(onNext: { sendResult in
                switch sendResult {
                case .failed(let message):
                   self.showValidateError(message)
                case .ok:
                    print(sendResult)
                default:
                    self.revertValidateError()
                }
            })
            .addDisposableTo(disposeBag)
        
        
        viewModel.doneResult?
            .drive(onNext: { doneResult in
                switch doneResult {
                case .failed(let message):
                    self.showValidateError(message)
                case .ok:
                    _ = self.navigationController?.popToRootViewController(animated: true)
                default:
                    self.revertValidateError()
                }
            })
            .addDisposableTo(disposeBag)
        
    }
    
    @objc func setupSendBunTitle() {
        timeCount -= 1
        if timeCount <= -1 {
            self.timer?.invalidate()
            self.sendBun.setTitle("Resend", for: UIControlState.normal)
            self.sendBun.isEnabled = true
            self.sendBun.alpha = 1
        }else{
            self.sendBun.setTitle("Resend(\(timeCount)s)", for: UIControlState.normal)
        }
    }
    

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.vcodeInvalidte?.drive(onNext: { result in
            switch result{
            case .failed(let message):
                self.showValidateError(message)
            default:
                self.revertValidateError()
            }
        })
            .addDisposableTo(disposeBag)
   
    }
    
    
    
    
    @IBAction func BackAction(_ sender: AnyObject) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    
}

extension ProtectAccountController {
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
