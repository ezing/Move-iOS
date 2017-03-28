//
//  UpgradeController.swift
//  Move App
//
//  Created by Wuju Zheng on 2017/3/8.
//  Copyright © 2017年 TCL Com. All rights reserved.
//

import UIKit
import CustomViews
import RxSwift
import RxCocoa

class UpgradeController: UIViewController {
    
    @IBOutlet weak var headImgV: UIImageView!
    @IBOutlet weak var nameLab: UILabel!
    @IBOutlet weak var batteryImgV: UIImageView!
    
    @IBOutlet weak var batteryLevel: UILabel!
    
    @IBOutlet weak var versionLab: UILabel!
    @IBOutlet weak var versionInfo: UILabel!
    
    @IBOutlet weak var tipLab: UILabel!
    @IBOutlet weak var downloadBun: UIButton!
    
    
    let activity = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    var viewModel: UpgradeViewModel!
    let disposeBag = DisposeBag()
    
    var enterCount = Variable(0)
    var downloadProgress = Variable(0)
    
    var downloadBlur: UIView?
    var progressLab: UILabel?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        self.setupUI()
        
        self.fetchProperty()
        
        viewModel = UpgradeViewModel(
            input: (
                enter: enterCount.asDriver(),
                downloadProgress: downloadProgress.asDriver(),
                downloadTaps: downloadBun.rx.tap.asDriver()
            ),
            dependency:(
                deviceManager: DeviceManager.shared,
                wireframe: DefaultWireframe.sharedInstance
            )
        )
        
        
        viewModel.downEnabled
            .drive(onNext: { [unowned self] valid, progress in
                self.makeDownloadBlur(progress: progress)
            })
            .addDisposableTo(disposeBag)
        
     
        
        let progress = MessageServer.share.progressDownload
        
        viewModel.downResult
            .drive(onNext: { [unowned self] result in
                switch result {
                case .failed(let message):
                    self.showMessage(message)
                case .ok(let message):
                    print(message)
                    self.updateDownloadButton(isEnable: false)
                    progress?.subscribe(
                    onNext: { info in
                        print("下载进度===\(info.content ?? "")")
                        self.downloadProgress.value = Int(info.content ?? "") ?? 0
                    }, onError: { (er) in
                        print(er)
                    }).addDisposableTo(self.disposeBag)
                default:
                    break
                }
            })
            .addDisposableTo(disposeBag)
    }
    
    
    func makeDownloadBlur(progress: Int) {
        if downloadBlur == nil{
            downloadBlur = UIView()
            downloadBlur?.backgroundColor = UIColor(rgb: 0x0092EB)
            downloadBlur?.layer.cornerRadius = 5
            self.downloadBun.addSubview(downloadBlur!)
        }
        
        if progressLab == nil {
            progressLab = UILabel(frame: CGRect(x: 0, y: 0, width: self.downloadBun.frame.size.width, height: self.downloadBun.frame.size.height))
            progressLab?.textAlignment = .center
            progressLab?.font = UIFont.systemFont(ofSize: 15)
            progressLab?.textColor = UIColor.white
            self.downloadBun.addSubview(progressLab!)
        }
        
        
        if progress > 0 && progress < 100 {
            let maxLength = downloadBun.frame.size.width
            downloadBlur?.frame = CGRect(x: 0, y: 0, width: CGFloat(progress)/100*maxLength, height: self.downloadBun.frame.size.height)
            progressLab?.text = "Download:\(progress)%"
            downloadBun.setTitle("", for: .disabled)
        }else{
            if progress >= 100 {
                self.fetchProperty()
            }
            downloadBlur?.removeFromSuperview()
            downloadBlur = nil
            progressLab?.removeFromSuperview()
            progressLab = nil
            downloadBun.setTitle("Download", for: .disabled)
        }
    }
    
    
    func updateDownloadButton(isEnable: Bool) {
        self.tipLab.isHidden = isEnable
        self.downloadBun.isEnabled = isEnable
        self.downloadBun.backgroundColor = UIColor(argb: isEnable ? 0xFF0092EB:0x880092EB)
    }
    
    
    func showMessage(_ text: String) {
        let vc = UIAlertController.init(title: "提示", message: text, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction.init(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
        vc.addAction(action)
        self.present(vc, animated: true) {
            
        }
    }
    
    func setupUI() {
        versionInfo.isHidden = true
        tipLab.isHidden = true
        downloadBun.isHidden = true
        
        let device = DeviceManager.shared.currentDevice!
        
        let placeImg = CDFInitialsAvatar(rect: CGRect(x: 0, y: 0, width: headImgV.frame.width, height: headImgV.frame.height), fullName: device.user?.nickname ?? "").imageRepresentation()!
        let imgUrl = URL(string: FSManager.imageUrl(with: device.user?.profile ?? ""))
        headImgV.kf.setImage(with: imgUrl, placeholder: placeImg)
        
        nameLab.text = device.user?.nickname ?? ""
        
        batteryLevel.text = "\(device.property?.power ?? 0)%"
        versionLab.text = "Firmware Version " + (device.property?.firmware_version ?? "")
        
        activity.center = self.view.center
        self.view.addSubview(activity)
        activity.startAnimating()
    }
    
    
    func fetchProperty() {
        let device = DeviceManager.shared.currentDevice!
        
        let propertyResult = DeviceManager.shared.getProperty(deviceId: device.deviceId!).flatMapLatest { property -> Observable<ValidationResult> in
            DeviceManager.shared.currentDevice?.property = property
            self.batteryLevel.text = "\(property.power ?? 0)%"
            self.batteryImgV.image = UIImage(named: "home_ic_battery\((property.power ?? 0)/20)")
            
            
            var checkInfo = DeviceVersionCheck(deviceId: device.deviceId, mode: "2", cktp: "2", curef: property.device_model, cltp: "10", type: "Firmware", fv: "")
            var ff = ""
            if let fv = property.firmware_version {
                if fv.characters.count > 6 {
                    let f1 = fv.substring(to: fv.index(fv.startIndex, offsetBy: 4))
                    let f2 = fv.substring(from: fv.index(fv.endIndex, offsetBy: -2))
                    ff.append(f1)
                    ff.append(f2)
                }
            }
            checkInfo.fv = ff
            checkInfo.curef = "MT\(property.device_model ?? "")"
            
            return self.checkVersion(checkInfo: checkInfo)
        }
        
        propertyResult.subscribe(onNext: { result in
            switch result {
            case .failed(let message):
                self.showMessage(message)
            default:
                break
            }
        }).addDisposableTo(disposeBag)
    }
    
    
    
    func checkVersion(checkInfo: DeviceVersionCheck) -> Observable<ValidationResult> {
        return DeviceManager.shared.checkVersion(checkInfo: checkInfo).map{ info -> ValidationResult in
            if info.currentVersion == info.newVersion {
                self.versionLab.text = "Firmware Version " + (info.currentVersion ?? "")
                self.versionInfo.isHidden = false
                self.versionInfo.text = "This watch's firmware is up to date."
                self.tipLab.isHidden = true
                self.downloadBun.isHidden = true
                self.updateDownloadButton(isEnable: true)
            }else{
                self.versionLab.text = "New Firmware Version " + (info.newVersion ?? "")
                self.versionInfo.isHidden = true
                self.tipLab.isHidden = true
                self.downloadBun.isHidden = false
                self.updateDownloadButton(isEnable: true)
            }
            self.activity.stopAnimating()
            return ValidationResult.ok(message: "Download Begin")
        }
    }
    
    
    
}
