//
//  AccountKidsRulesuserController.swift
//  Move App
//
//  Created by Vernon yellow on 17/2/21.
//  Copyright © 2017年 TCL Com. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import CustomViews


class AccountKidsRulesuserController: UITableViewController {
    
    @IBOutlet weak var watchContactCell: UITableViewCell!

    //internationalization
    @IBOutlet weak var kidswatchTitleItem: UINavigationItem!
    @IBOutlet weak var watchContactLabel: UILabel!
    @IBOutlet weak var safeZoneLabel: UILabel!
    @IBOutlet weak var schoolTimeLabel: UILabel!
    @IBOutlet weak var reminderLabel: UILabel!
    @IBOutlet weak var regularShutdownLabel: UILabel!
    @IBOutlet weak var unpairedwithWatchLabel: UILabel!
    @IBOutlet weak var unpairedwithwatchIntroduceLabel: UILabel!
    @IBOutlet weak var savepowerLabel: UILabel!
    @IBOutlet weak var savepowerIntroduceLabel: UILabel!
    @IBOutlet weak var usePermissiorLabel: UILabel!
    @IBOutlet weak var timeZoneLabel: UILabel!
    @IBOutlet weak var languageforthiswatchLabel: UILabel!
    @IBOutlet weak var apnLabel: UILabel!
    @IBOutlet weak var updateLabel: UILabel!
    @IBOutlet weak var updateNewLab: UILabel!
    @IBOutlet weak var unpairedWithLabel: UILabel!
    
    
    @IBOutlet weak var headQutlet: UIImageView!
    @IBOutlet weak var accountNameQutlet: UILabel!
    
    @IBOutlet weak var autoAnswerQutel: SwitchButton!
    @IBOutlet weak var savePowerQutel: SwitchButton!
    
    var isAdmin = false

    let disposeBag = DisposeBag()
    
    let enterSubject = PublishSubject<Bool>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateNewLab.isHidden = true

        initializeI18N()

        let viewModel = AccountKidsRulesuserViewModel(
            input: (
                savePower: savePowerQutel.rx.value.asDriver(),
                autoAnswer: autoAnswerQutel.rx.value.asDriver()
            ),
            dependency: (
                settingsManager: WatchSettingsManager.share,
                validation: DefaultValidation.shared,
                wireframe: DefaultWireframe.sharedInstance
            )
        )
        
        viewModel.saveFinish
            .drive(onNext:{_ in
            }).addDisposableTo(disposeBag)
        
        viewModel.savePowerEnable.drive(savePowerQutel.rx.on).addDisposableTo(disposeBag)
        viewModel.autoAnswereEnable.drive(autoAnswerQutel.rx.on).addDisposableTo(disposeBag)
        
        viewModel.activityIn
            .map({ !$0 })
            .drive(onNext: userInteractionEnabled)
            .addDisposableTo(disposeBag)
        
        // 判断当前是否是管理员
        RxStore.shared.deviceIdObservable
            .flatMapLatest { DeviceManager.shared.getContacts(deviceId: $0).catchErrorJustReturn([]) }
            .filterEmpty()
            .map { contacts in contacts.filter { $0.admin == true }.first?.uid }
            .filterNil()
            .withLatestFrom(RxStore.shared.uidObservable) { $0 == $1 }
            .bindNext { [weak self] in
                self?.isAdmin = $0
                self?.tableView.reloadData()
            }
            .addDisposableTo(disposeBag)
        
        RxStore.shared.currentDevice
            .bindNext { [weak self] in self?.show(deviceInfo: $0) }
            .addDisposableTo(disposeBag)
        
        let property = RxStore.shared.deviceIdObservable
            .flatMapLatest { id -> Observable<DeviceProperty> in
                DeviceManager.shared.getProperty(deviceId: id).catchErrorJustReturn(DeviceProperty()).filter({ $0.power != nil })
            }
        property.bindNext { RxStore.shared.bind(property: $0) }.addDisposableTo(disposeBag)
        
        RxStore.shared.currentDevice
            .flatMapLatest { (device) -> Observable<DeviceVersion> in
                guard let deviceId = device.deviceId, let property = device.property else {
                    return Observable.empty()
                }
                
                var checkInfo = DeviceVersionCheck(deviceId: deviceId, mode: "2", cktp: "2", curef: property.device_model, cltp: "10", type: "Firmware", fv: "")
                var ff = ""
                if let fv = property.firmware_version {
                    if fv.characters.count > 6 {
                        ff = fv.substring(with:  Range<String.Index>(uncheckedBounds: (lower: fv.index(fv.startIndex, offsetBy: 4), upper: fv.index(fv.endIndex, offsetBy: -2))))
                    }
                }
                checkInfo.fv = ff
                return DeviceManager.shared.checkVersion(checkInfo: checkInfo)
            }
            .map{ $0.newVersion == nil }
            .bindTo(updateNewLab.rx.isHidden)
            .addDisposableTo(disposeBag)
        
        KidSettingsManager.shared.fetchreminder()
            .map { $0.alarms }
            .filter { $0.count == 0 }
            .flatMapLatest { (_) in
                KidSettingsManager.shared.creadAlarm(KidSetting.Reminder.Alarm(alarmAt: Date(timeIntervalSince1970: 28800), day: [true,true,true,true,true,false,false], active: false))
            }
            .bindNext { Logger.debug($0) }
            .addDisposableTo(disposeBag)
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false
        enterSubject.onNext(true)
        propelToTargetController()
    }

    
    func userInteractionEnabled(enable: Bool) {
       
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //unpair
        if let vc = R.segue.accountKidsRulesuserController.showUnpairTip(segue: segue)?.destination {
            vc.isMaster = self.isAdmin
            vc.unpairBlock = { flag, message in
                if flag {
                    _ = self.navigationController?.popToRootViewController(animated: true)
                } else {
                    self.showAlert(message: message)
                }
            }
        }
        //apn
        if let vc = R.segue.accountKidsRulesuserController.showApn(segue: segue)?.destination {
            vc.hasPairedWatch = true
            vc.imei = RxStore.shared.currentDeviceId.value!
        }
        //infomation
        if let vc = R.segue.accountKidsRulesuserController.showKidInfomation(segue: segue)?.destination {
            vc.isForSetting = true
            let kidInfo = DeviceManager.shared.currentDevice?.user
            var info = DeviceBindInfo()
            info.nickName = kidInfo?.nickname
            info.number = kidInfo?.number
            info.gender = kidInfo?.gender
            info.height = kidInfo?.height
            info.weight = kidInfo?.weight
            info.heightUnit = kidInfo?.heightUnit
            info.weightUnit = kidInfo?.weightUnit
            info.birthday = kidInfo?.birthday
            info.profile = kidInfo?.profile
            
            vc.addInfoVariable.value = info
        }
    }
    
}

extension AccountKidsRulesuserController {
    
    func propelToTargetController() {
        if let target = Distribution.shared.target {
            switch target {
            case .kidInformation:
                showKidInformationController()
                Distribution.shared.target = nil
            case .familyMember:
                showFamilyMemberController()
                Distribution.shared.target = nil
            case .friendList:
                showFriendListController()
                Distribution.shared.target = nil
            }
        }
    }
    
    fileprivate func showKidInformationController() {
        self.performSegue(withIdentifier: R.segue.accountKidsRulesuserController.showKidInfomation, sender: nil)
    }
    
    fileprivate func showAlert(message text: String) {
        let alert = UIAlertController(title: "提示", message: text, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(action)
        self.present(alert, animated: true)
    }
    
    fileprivate func show(deviceInfo: DeviceInfo) {
        let imageRect = CGRect(x: 0, y: 0, width: self.headQutlet.frame.width, height: self.headQutlet.frame.height)
        let placeImage = CDFInitialsAvatar(rect: imageRect, fullName: deviceInfo.user?.nickname ?? "").imageRepresentation()!
        let imgUrl = URL(string: FSManager.imageUrl(with: deviceInfo.user?.profile ?? ""))
        self.headQutlet.kf.setImage(with: imgUrl, placeholder: placeImage)
        self.accountNameQutlet.text = deviceInfo.user?.nickname
    }
    
    fileprivate func initializeI18N() {
        //判断用户，没有多语言字串
        //kidswatchTitleItem.title =
        
        watchContactLabel.text = R.string.localizable.watch_contact()
        safeZoneLabel.text = R.string.localizable.safe_zone()
        schoolTimeLabel.text = R.string.localizable.school_time()
        reminderLabel.text = R.string.localizable.reminder()
        regularShutdownLabel.text = R.string.localizable.reminder()
        regularShutdownLabel.text = R.string.localizable.regular_shutdown()
        unpairedwithWatchLabel.text = R.string.localizable.auto_answer_call()
        unpairedwithwatchIntroduceLabel.text = R.string.localizable.auto_answer_call_describe()
        savepowerLabel.text = R.string.localizable.save_power()
        savepowerIntroduceLabel.text = R.string.localizable.save_power_describe()
        timeZoneLabel.text = R.string.localizable.time_zone()
        languageforthiswatchLabel.text = R.string.localizable.language_for_watch()
        apnLabel.text = R.string.localizable.apn()
        updateLabel.text = R.string.localizable.update()
        unpairedWithLabel.text = R.string.localizable.unpaired_with_watch()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1, indexPath.row == 0 {
            if isAdmin {
                if let toVC = R.storyboard.contact.instantiateInitialViewController() {
                    self.navigationController?.show(toVC, sender: nil)
                }
            } else {
                showFamilyMemberController()
            }
        }
    }
    
    fileprivate func showFamilyMemberController() {
        if let toVC = R.storyboard.contact.familyMemberController() {
            self.navigationController?.show(toVC, sender: nil)
        }
    }
    
    fileprivate func showFriendListController() {
        if let toVC = R.storyboard.contact.watchFriends() {
            self.navigationController?.show(toVC, sender: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let heightAtAdmin =  [[55], [44, 44, 44, 44, 44], [95, 95, 44, 44, 44, 44, 44, 44]]
        let heightNotAdmin = [[55], [44, 44, 44, 44,  0], [ 0,  0,  0,  0,  0,  0,  0, 44]]
        let height = isAdmin ? heightAtAdmin : heightNotAdmin
        return CGFloat(height[indexPath.section][indexPath.row])
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return R.string.localizable.function()
        }
        if section == 2 {
            return R.string.localizable.action_settings()
        }
        return nil
    }
}

