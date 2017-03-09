//
//  MainMapController.swift
//  Move App
//
//  Created by Jiang Duan on 17/2/9.
//  Copyright © 2017年 TCL Com. All rights reserved.
//

import UIKit
import MapKit
import RxSwift
import RxCocoa
import SVPulsingAnnotationView
import Realm
import RealmSwift

//private extension Reactive where Base: MKMapView {
//    var singleAnnotion: UIBindingObserver<Base, MKAnnotation> {
//        return UIBindingObserver(UIElement: base) { mapView, annotion in
//            mapView.removeAnnotations(mapView.annotations)
//            mapView.addAnnotation(annotion)
//        }
//    }
//}

class MainMapController: UIViewController {
    
    var disposeBag = DisposeBag()
    var isOpenList : Bool? = false
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet var noGeolocationView: UIView!
    @IBOutlet weak var openPreferencesBtn: UIButton!
    
    @IBOutlet weak var objectImageBtn: UIButton!
    @IBOutlet weak var objectNameL: UILabel!
    @IBOutlet weak var objectNameLConstraintWidth: NSLayoutConstraint!
    @IBOutlet weak var objectLocationL: UILabel!
    @IBOutlet weak var signalImageV: UIImageView!
    @IBOutlet weak var electricV: UIImageView!
    @IBOutlet weak var electricL: UILabel!
    @IBOutlet weak var objectLocationTimeL: UILabel!
    
    
    
    var mapDeviceList : MapDeviceListView?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.title = "Location"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapDeviceList = Bundle.main.loadNibNamed("MapDeviceListView", owner: self, options: nil)?.first as! MapDeviceListView?
        mapDeviceList?.frame = CGRect(x: objectImageBtn.frame.minX, y : mapView.frame.minY, width : objectImageBtn.frame.size.width*2, height : objectImageBtn.frame.size.height*5)
        self.view.addSubview(mapDeviceList!)
        mapDeviceList?.isHidden = true
        
        noGeolocationView.frame = view.bounds
        view.addSubview(noGeolocationView)
        
        // Do any additional setup after loading the view.
        
        let geolocationService = GeolocationService.instance
        let viewModel = MainMapViewModel(input: (),
                                         dependency: (
                                            geolocationService: geolocationService,
                                            kidInfo: MokKidInfo()
            )
        )
        
        viewModel.authorized
            .drive(noGeolocationView.rx.isHidden)
            .addDisposableTo(disposeBag)
        
        openPreferencesBtn.rx.tap
            .bindNext { [weak self] in
                self?.openAppPreferences()
            }
            .addDisposableTo(disposeBag)
        
        mapView.rx.willStartLoadingMap
            .asDriver()
            .drive(onNext: {
                Logger.debug("地图开始加载!")
            })
            .addDisposableTo(disposeBag)
        
        mapView.rx.didFinishLoadingMap
            .asDriver()
            .drive(onNext: {
                Logger.debug("地图结束加载!")
            })
            .addDisposableTo(disposeBag)
        
        mapView.rx.didAddAnnotationViews
            .asDriver()
            .drive(onNext: {
                Logger.debug("地图Annotion个数: \($0.count)")
            })
            .addDisposableTo(disposeBag)
        
        viewModel.kidLocation
            .asObservable()
            .take(1)
            .bindNext { [unowned self] in
                let region = MKCoordinateRegionMakeWithDistance($0, 500, 500)
                self.mapView.setRegion(region, animated: true)
            }
            .addDisposableTo(disposeBag)
        
        viewModel.kidAnnotion
            .distinctUntilChanged()
            .drive(onNext: { [unowned self] annotion in
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.mapView.addAnnotation(annotion)
        })
            .addDisposableTo(disposeBag)
        
//        mapView.addAnnotation(BaseAnnotation(CLLocationCoordinate2DMake(23.227465, 113.190765)))
    }
    
    @IBAction func locationBtnClick(_ sender: UIButton) {
        
    }
    
    @IBAction func routeBtnClick(_ sender: UIButton) {
        
    }
    
    @IBAction func turnToStepCounterBtnClick(_ sender: UIButton) {
        
    }
    
    @IBAction func MobilePhoneBtnClick(_ sender: UIButton) {
        
    }
    
    @IBAction func MobileMessageBtnClick(_ sender: UIButton) {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func AvatarImageClick(_ sender: UIButton) {
        if isOpenList == false {
            mapDeviceList?.isHidden = false
            isOpenList = true
        }else {
            mapDeviceList?.isHidden = true
            isOpenList = false
        }
    }
    
    
    private func openAppPreferences() {
        UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    func powerToAnimation(num : Int) {
        electricL.text = String(format:"%d%",num)
        if num == 0{
            electricV.image = UIImage(named: "home_ic_battery0")
        }else if num < 20 && num > 0{
            electricV.image = UIImage(named: "home_ic_battery1")
        }else if num < 40 && num > 20 {
            electricV.image = UIImage(named: "home_ic_battery2")
        }else if num < 60 && num > 40 {
            electricV.image = UIImage(named: "home_ic_battery3")
        }else if num < 80 && num > 60 {
            electricV.image = UIImage(named: "home_ic_battery4")
        }else if num < 100 && num > 80 {
            electricV.image = UIImage(named: "home_ic_battery5")
        }
    }
}

extension MainMapController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is BaseAnnotation {
            let identifier = "LocationAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if annotationView == nil {
                annotationView = ContactAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            annotationView?.canShowCallout = false
            return annotationView
        }
        
        return nil
    }
}
