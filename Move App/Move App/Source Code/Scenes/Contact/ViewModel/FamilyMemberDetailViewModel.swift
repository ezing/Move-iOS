//
//  FamilyMemberDetailViewModel.swift
//  Move App
//
//  Created by Wuju Zheng on 2017/3/11.
//  Copyright © 2017年 TCL Com. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxOptional


class FamilyMemberDetailViewModel {
    
    var nameInvalidte: Driver<ValidationResult>?
    var phoneInvalidte: Driver<ValidationResult>?
    
    
    var saveEnabled: Driver<Bool>?
    var saveResult: Driver<ValidationResult>?
    
    var masterResult: Driver<ValidationResult>?
    var deleteResult: Driver<ValidationResult>?
    
    var contactInfo: Variable<ImContact>?
    
    var masterInfo: ImContact?
    
    let sending: Driver<Bool>
    
    init(
        input:(
        photo: Variable<UIImage?>,
        name: Variable<Relation?>,
        number: Variable<String?>,
        masterTaps: Driver<Bool>,
        deleteTaps: Driver<Bool>,
        saveTaps: Driver<Void>
        ),
        dependency: (
        deviceManager: DeviceManager,
        validation: DefaultValidation,
        wireframe: DefaultWireframe
        )
        ) {
        
        let deviceManager = dependency.deviceManager
        _ = dependency.validation
        _ = dependency.wireframe
        
        
        let activity = ActivityIndicator()
        sending = activity.asDriver()
        
        let identityInvalidte = input.name.asDriver().map({$0 != nil})
        let numberInvalidte = input.number.asDriver().map({$0 != nil && $0 != ""})
        
        
        saveEnabled = Driver.combineLatest(identityInvalidte, numberInvalidte, sending){$0 && $1 && !$2}
            .distinctUntilChanged()
        
        
        masterResult = input.masterTaps.filter({$0 == true})
            .flatMapLatest({ _ -> Driver<ImContact?> in
                if var mf = self.masterInfo {
                    mf.flag = self.clearEmergency(flag: mf.flag ?? 0)
                    return Driver.just(mf)
                }else{
                    return Driver.just(nil)
                }
            })
            .filterNil()
            .flatMapLatest({result -> Driver<Bool>  in
                return deviceManager.settingContactInfo(contactInfo: result).asDriver(onErrorJustReturn: false)
            })
            .flatMapLatest({_ -> Driver<String?> in
                var info = self.contactInfo?.value
                info?.flag = self.setEmergency(flag: info?.flag ?? 0)
                return deviceManager.settingContactInfo(contactInfo: info!).map({_ in
                    return info?.uid
                })
                .asDriver(onErrorJustReturn: nil)
            })
            .filterNil()
            .flatMapLatest({result in
                return deviceManager.settingAdmin(uid: result).map({ _ in
                    return ValidationResult.ok(message: "Set Success.")
                })
                .asDriver(onErrorRecover: commonErrorRecover)
            })
        
        
        deleteResult = input.deleteTaps.filter({$0 == true})
            .flatMapLatest({ _ in
                return deviceManager.deleteContact(uid: (self.contactInfo?.value.uid)!).map({ _ in
                    return ValidationResult.ok(message: "Delete Success.")
                }).asDriver(onErrorRecover: commonErrorRecover)
            })
        
        saveResult = input.saveTaps
            .flatMapLatest({ _ in
                var info = (self.contactInfo?.value)!
                info.identity = input.name.value
                info.phone = input.number.value
                
                if let photo = input.photo.value {
                    return FSManager.shared.uploadPngImage(with: photo).map{$0.fid}.filterNil().takeLast(1)
                        .trackActivity(activity)
                        .flatMapLatest({ fid -> Observable<ValidationResult> in
                            info.profile = fid
                            return deviceManager.settingContactInfo(contactInfo: info)
                                .map({ _ in
                                    return ValidationResult.ok(message: "Set Success.")
                                })
                        })
                        .asDriver(onErrorRecover: commonErrorRecover)
                }else{
                    return deviceManager.settingContactInfo(contactInfo: info)
                        .trackActivity(activity)
                        .map({ _ in
                            return ValidationResult.ok(message: "Set Success.")
                        })
                        .asDriver(onErrorRecover: commonErrorRecover)
                }
            })
        
    }
    
    
    
    func setEmergency(flag: Int) -> Int {
        return flag | 0x0100
    }
    
    func clearEmergency(flag: Int) -> Int {
        return Int(UInt(flag) & ~UInt(0x0100))
    }
    
}

