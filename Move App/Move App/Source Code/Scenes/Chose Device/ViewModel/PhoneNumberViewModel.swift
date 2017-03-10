//
//  PhoneNumberViewModel.swift
//  Move App
//
//  Created by Wuju Zheng on 2017/2/28.
//  Copyright © 2017年 TCL Com. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa


class PhoneNumberViewModel {
    
    let phoneInvalidte: Driver<ValidationResult>
    
    let sending: Driver<Bool>
    
    let nextEnabled: Driver<Bool>
    let nextResult: Driver<ValidationResult>
    
    
    init(
        input: (
        phone: Driver<String>,
        nextTaps: Driver<Void>
        ),
        dependency: (
        userManager: UserManager,
        validation: DefaultValidation,
        wireframe: Wireframe
        )
        ) {
        
        _ = dependency.userManager
        _ = dependency.validation
        _ = dependency.wireframe
        
//        let activity = ActivityIndicator()
        self.sending = Driver.just(false)
        
        
        phoneInvalidte = input.phone.map { phone in
                if phone.characters.count > 0{
                    return ValidationResult.ok(message: "")
                }
                return ValidationResult.empty
        }
        
        
        nextEnabled = Driver.combineLatest(
            phoneInvalidte,
            sending) { phone, sending in
                phone.isValid && !sending
            }
            .distinctUntilChanged()
        
        
        nextResult = input.nextTaps
            .map({ _ in
                return ValidationResult.ok(message: "Send Success.")
            })
            .asDriver(onErrorRecover: pwdRecoveryErrorRecover)
        
    }
    
}

fileprivate func pwdRecoveryErrorRecover(_ error: Error) -> Driver<ValidationResult> {
    guard error is WorkerError else {
        return Driver.just(ValidationResult.empty)
    }
    
    return Driver.just(ValidationResult.failed(message: "Send faild"))
}
