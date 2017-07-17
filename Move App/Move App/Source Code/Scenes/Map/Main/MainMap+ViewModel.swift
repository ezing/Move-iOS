//
//  MainMapViewModel.swift
//  Move App
//
//  Created by Jiang Duan on 17/2/10.
//  Copyright © 2017年 TCL Com. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import MapKit
import RxOptional


class MainMapViewModel {
    // outputs {
    
    let authorized: Driver<Bool>
    
    let kidLocation: Observable<CLLocationCoordinate2D>
    let kidAddress: Observable<String>
    let kidType: Observable<KidSate.LocationTypeSet>
    let locationTime: Observable<Date>
    
    let kidAnnotion: Observable<AccuracyAnnotation>
    
    let singleAction: Observable<DeviceInfo>
    let allAction: Observable<[DeviceInfo]>
    
    let activityIn: Driver<Bool>
    
    let devicesVariable: Variable<[DeviceInfo]>
    let currentDevice: Driver<DeviceInfo>
    
    let currentProperty: Observable<DeviceProperty>
    
    let fetchDevices: Driver<[DeviceInfo]>
    
    let remindSuccess: Observable<Bool>
    let remindActivityIn: Driver<Bool>
    
    let errorObservable: Observable<Error>
    
    let badgeCount: Observable<Int>
    
    let battery: Observable<Int>
    
    let online: Driver<Bool>
    
    let autoPosistion: Driver<Bool>
    
    // }
    
    init(
        input: (
            enter: Driver<Void>,
            avatarTap: Driver<Void>,
            offTrackingModeTap: Driver<Void>,
            avatarView: UIView,
            isAtThisPage: Variable<Bool>,
            remindLocation: Observable<Void>
        ),
         dependency: (
            geolocationService: GeolocationService,
            deviceManager: DeviceManager,
            settingsManager: WatchSettingsManager,
            locationManager: LocationManager,
            wireframe: AlertWireframe
        )
        ) {
        
        authorized = dependency.geolocationService.authorized
        let _ = dependency.geolocationService.location
        let deviceManager = dependency.deviceManager
        let locationManager = dependency.locationManager
        let settingsManager = dependency.settingsManager
        let wireframe = dependency.wireframe
        let isAtThisPage = input.isAtThisPage.asObservable()
        
        let activitying = ActivityIndicator()
        self.activityIn = activitying.asDriver()
        
        let currentDeviceId = RxStore.shared.currentDeviceId.asDriver()
        let currentDeviceIdObservable = currentDeviceId.asObservable().filterNil()
        devicesVariable = RxStore.shared.deviceInfosState

        currentDevice = Driver.combineLatest(devicesVariable.asDriver(),
                                             currentDeviceId.filterNil()) { (devices, id) in devices.filter({$0.deviceId == id}).first }
            .filterNil()
        
        let enter = input.enter
        
        fetchDevices = enter
            .flatMapLatest {
                deviceManager.fetchDevices()
                    .trackActivity(activitying)
                    .catchErrorEmpty()
                    .asDriver(onErrorJustReturn: [])
            }
        
        let period = Observable<Int>.timer(2,
                                           period: Configure.App.LoadDataOfPeriod,
                                           scheduler: MainScheduler.instance)
            .withLatestFrom(isAtThisPage)
            .filterTrue()
            .shareReplay(1)
        

        let onlineObservable = Observable.merge(period, currentDeviceIdObservable.mapVoid())
            .delay(1.0, scheduler: MainScheduler.instance)
            .flatMapLatest { deviceManager.online.trackActivity(activitying).catchErrorEmpty() }
        online = onlineObservable.asDriver(onErrorJustReturn: false)
        
        let remindActivitying = BehaviorSubject<Bool>(value: false)
        self.remindActivityIn = remindActivitying.asDriver(onErrorJustReturn: false)
        
        let errorSubject = PublishSubject<Error>()
        
        // 通知： 后台进入APP
        let enterForeground = NotificationCenter.default.rx.notification(.UIApplicationWillEnterForeground)
            .withLatestFrom(online.asObservable()) { $1 ? $0 : nil }
            .filterNil()
            .withLatestFrom(remindActivitying.asObservable())
            .filter { !$0 }
            .mapVoid()
        
        remindSuccess = Observable.merge(enterForeground, input.remindLocation)
            .startWith(())
            .throttle(3.0, scheduler: MainScheduler.instance)
            .withLatestFrom(currentDeviceId.asObservable().filterNil())
            .do(onNext: { _ in remindActivitying.onNext(true) })
            .flatMapLatest {
                deviceManager.remindLocation(deviceId: $0)
                    .trackActivity(activitying)
                    .do(onError: { errorSubject.onNext($0) })
                    .catchErrorJustReturn(false)
            }
            .share()
        
        let remindLocation = remindSuccess
            .flatMapLatest { _ in MessageServer.share.manuallyLocate }
            .do(onNext: { _ in remindActivitying.onNext(false) })
            .share()
        
        let remindTimeOut = remindSuccess.flatMapLatest{ _ in
                Observable.just(())
                    .delay(60.0, scheduler: MainScheduler.instance)
                    .withLatestFrom(remindActivitying.asObservable())
                    .filter { $0 }
                    .map{ _ in WorkerError.LocationTimeout as Error }
                    .do(onNext: { _ in remindActivitying.onNext(false) })
            }
        
        errorObservable = Observable.merge(errorSubject.asObserver(), remindTimeOut)
            .withLatestFrom(isAtThisPage) { $1 ? $0 : nil }
            .filterNil()
        
        let currentLocation = Observable.merge(period,
                                               currentDeviceIdObservable.mapVoid())
            .flatMapLatest {
                locationManager.currentLocation
                    .trackActivity(activitying)
                    .catchErrorEmpty()
            }
            .shareReplay(1)
        
        currentProperty = period
            .withLatestFrom(currentDeviceId.asObservable())
            .filterNil()
            .flatMapLatest {
                deviceManager.getProperty(deviceId: $0)
                    .trackActivity(activitying)
                    .catchErrorEmpty()
            }
            .shareReplay(1)
        
        kidLocation = Observable.merge(currentLocation, remindLocation)
            .map{ $0.location }
            .filterNil()
            .distinctUntilChanged { $0.latitude == $1.latitude && $0.longitude == $1.longitude }
            .do(onNext: { _ in remindActivitying.onNext(false) })
            .share()
        
        kidAddress = Observable.merge(currentLocation, remindLocation).map{ $0.address }.filterNil()
        kidType = Observable.merge(currentLocation, remindLocation).map{ $0.type }.filterNil()
        locationTime = Observable.merge(currentLocation, remindLocation).map{ $0.time }.filterNil()
        
        let accuracy = Observable.merge(currentLocation, remindLocation).map { $0.accuracy }.filterNil().distinctUntilChanged()
        kidAnnotion = Observable.combineLatest(kidLocation, accuracy) { AccuracyAnnotation($0, accuracy: $1) }
        
        let kidInfos = input.avatarTap
            .withLatestFrom(devicesVariable.asDriver())
        
        let userID = RxStore.shared.uidObservable
        
        let popoer = RxPopover.shared
        popoer.style = .dark
        let selecedAction = kidInfos.asObservable()
            .map(allAndTransformAction)
            .withLatestFrom(userID, resultSelector: allAndTransformActions)
            .flatMapLatest{ actions in
                popoer.promptFor(toView: input.avatarView, actions: actions)
            }
            .shareReplay(1)
        
        allAction = selecedAction.map({ $0.data as? [DeviceInfo] }).filterNil()
        singleAction = selecedAction.map({ $0.data as? DeviceInfo  }).filterNil()
        
        
        let devUID = currentDevice.map{ $0.user?.uid }.filterNil().asObservable()
        badgeCount = Observable.combineLatest(userID, devUID) { ($0, $1) }
            .flatMapLatest { IMManager.shared.countUnreadMessages(uid: $0, devUid: $1) }
        
        let uploadPower = enterForeground
            .withLatestFrom(currentDevice.asObservable())
            .map{ $0.deviceId }
            .filterNil()
            .flatMapLatest {
                deviceManager.uploadPower(deviceId: $0)
                    .trackActivity(activitying)
                    .catchErrorJustReturn(false)
            }
            .filterTrue()
        
        battery = Observable.merge(MessageServer.share.lowBattery,
                                   uploadPower)
            .flatMapLatest{
                deviceManager.power
                    .trackActivity(activitying)
                    .catchErrorEmpty()
            }
        
        
        let fetchAutoPosistion = Driver.merge(currentDevice.distinctUntilChanged{ $0.deviceId == $1.deviceId },
                                              enter.withLatestFrom(currentDevice))
            .withLatestFrom(userID.asDriver(onErrorJustReturn: "").filterEmpty()) { ($0.user?.owner == $1) ? $0 : nil }
            .filterNil()
            .flatMapLatest {
                settingsManager.fetchautoPosistion(devID: $0.deviceId)
                    .trackActivity(activitying)
                    .asDriver(onErrorJustReturn: false)
            }
        
        let offTrackingMode = input.offTrackingModeTap
            .flatMapLatest{
                wireframe.promptYHFor("Turning off Daily tracking mode, the Safezone loction information will be not timely",
                                      cancelAction: CommonResult.cancel,
                                      action: CommonResult.ok)
                    .filter { $0.isOK }
                    .asDriver(onErrorJustReturn: .cancel)
            }
            .flatMapLatest { _ in
                settingsManager.update(autoPosistion: false)
                    .trackActivity(activitying)
                    .asDriver(onErrorJustReturn: false)
            }
            .filter { $0 }
            .withLatestFrom(currentDevice.map{ $0.deviceId }.filterNil())
            .flatMapLatest {
                settingsManager.fetchautoPosistion(devID: $0)
                    .trackActivity(activitying)
                    .asDriver(onErrorJustReturn: false)
            }
        
        autoPosistion = Driver.merge(currentDevice.map{ $0.deviceId }.distinctUntilChanged().filterNil().map{_ in false },
                                     fetchAutoPosistion,
                                     offTrackingMode)
        
    }
}

fileprivate func transformAction(infos: [DeviceInfo]) -> [BasePopoverAction] {
    return infos.map { BasePopoverAction(info: $0) }
}

fileprivate func allAndTransformAction(infos: [DeviceInfo]) -> [BasePopoverAction] {
    return [BasePopoverAction(infos: infos)] + transformAction(infos: infos)
}

fileprivate func allAndTransformActions(_ actions: [BasePopoverAction], userID: String) -> [BasePopoverAction] {
    return actions.map{ transformAction(action: $0, userID: userID) }
}

fileprivate func transformAction(action: BasePopoverAction, userID: String) -> BasePopoverAction {
    guard
        let device = action.data as? DeviceInfo,
        let devUid = device.user?.uid else {
        return action
    }
    
    let cNotices = ImDateBase.shared.countUnreadNoticeAtPage(uid: userID, devUid: devUid)
    let cMessages = ImDateBase.shared.countUnreadMessage(uid: userID, devUid: devUid)
    action.hasBadge = (cNotices + cMessages) > 0
    return action
}

extension BasePopoverAction {
    
    convenience init(info: DeviceInfo) {
        self.init(imageUrl: info.user?.profile?.fsImageUrl,
                  placeholderImage: R.image.home_pop_all(),
                  title: info.user?.nickname,
                  isSelected: true,
                  handler: nil)
        self.canAvatar = true
        self.data = info
    }
    
    convenience init(infos: [DeviceInfo]) {
        self.init(imageUrl: nil,
                  placeholderImage: R.image.home_pop_all(),
                  title: R.string.localizable.id_all(),
                  isSelected: true,
                  handler: nil)
        self.data = infos
    }
    
}


extension ObservableType {
    
    func mapVoid() -> Observable<Void> {
        return self.map{_ in () }
    }
}

extension ObservableType where E == Bool {
    
    func filterTrue() -> Observable<Void> {
        return self.filter { $0 }.map { _ in () }
    }
}