//
//  UpgradeViewModel.swift
//  Move App
//
//  Created by Wuju Zheng on 2017/3/8.
//  Copyright © 2017年 TCL Com. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class UpgradeViewModel {
    
    let sending: Driver<Bool>
    let downloading: Driver<(Bool, Int)>
    
    let downEnabled: Driver<(Bool, Int)>
    let downResult: Driver<ValidationResult>
    
  
    
    init(
        input: (
            enter: Driver<Int>,
            downloadProgress: Driver<Int>,
            downloadTaps: Driver<Void>
        ),
        dependency: (
            deviceManager: DeviceManager,
            wireframe: Wireframe
        )
        ) {
        
        
        let deviceManager = dependency.deviceManager
        _ = dependency.wireframe
        
        let activity = ActivityIndicator()
        self.sending = activity.asDriver()
        
        self.downloading = input.downloadProgress.map({ p in
            return (p > 0 && p < 100 , p)
        })
        
        downEnabled = Driver.combineLatest(sending, downloading){(!$0 && !$1.0, $1.1)}
        
        
        
        downResult = input.downloadTaps.flatMapLatest({ _ in
             deviceManager.sendNotify(deviceId: (deviceManager.currentDevice?.deviceId)!, code: DeviceNotify.downloadFirmware)
                .trackActivity(activity)
//                .flatMapLatest({ _ -> Driver<String> in
//                    guard let progress = MessageServer.share.progressDownload else {
//                        return Driver.just("")
//                    }
//                    return progress.map({ $0.content }).filterNil().asDriver(onErrorJustReturn: "")
//                })
                .map{ _ in
                    return ValidationResult.ok(message: "Download Begin")
                }
                .asDriver(onErrorRecover: errorRecover)
        })
        
        
    }
    
 
}



fileprivate func errorRecover(_ error: Error) -> Driver<ValidationResult> {
    guard error is WorkerError else {
        return Driver.just(ValidationResult.empty)
    }
    
    return Driver.just(ValidationResult.failed(message: "Set faild"))
}
