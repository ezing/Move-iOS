//
//  SafeZoneViewModel.swift
//  Move App
//
//  Created by lx on 17/3/16.
//  Copyright © 2017年 TCL Com. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import MapKit
import RxOptional

class SafeZoneViewModel {

    let userLocation: Driver<CLLocationCoordinate2D>
    
    let kidLocation: Driver<CLLocationCoordinate2D>
    let kidAnnotion: Driver<BaseAnnotation>
    
    
    init(input: (),dependency: (
        geolocationService: GeolocationService,
        locationManager: LocationManager,
        kidinfo:MokKidInfo
        )
        ) {
        
        userLocation = dependency.geolocationService.location
        let locationManager = dependency.locationManager
        
//        Me.shared.currDeviceID
        
        kidLocation = Driver<Int>.timer(2, period: Configure.App.LoadDataOfPeriod)
            .flatMapLatest ({_ in
                locationManager.getCurrentLocation()
                    .map({
                        $0.location
                    })
                    .debug()
                    .filterNil()
                    .asDriver(onErrorRecover: {_ in
                        dependency.geolocationService.location
                    })
            })
        
        kidAnnotion = kidLocation
            .map { BaseAnnotation($0) }
        
        
    }
    
    func getdata(deviceid : String) -> Observable<MoveApi.LocationInfo> {
        return MoveApi.Location.getNew(deviceId: deviceid).map({ $0.location }).filterNil()
    }
}

class MokKidInfo {
}
