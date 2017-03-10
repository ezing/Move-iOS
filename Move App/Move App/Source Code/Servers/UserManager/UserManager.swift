//
//  UserManager.swift
//  Move App
//
//  Created by Jiang Duan on 17/2/8.
//  Copyright © 2017年 TCL Com. All rights reserved.
//


import Foundation
import RxSwift


class UserManager {
    
    static let shared = UserManager()

    fileprivate var worker: UserWorkerProtocl!
    private let userInfo = UserInfo.shared
    
    init() {
        worker = MoveApiUserWorker()
    }
}

extension UserManager {
    
    func getProfile() -> Observable<UserInfo.Profile> {
        return worker.fetchProfile()
    }
    
    func login(email: String, password: String) -> Observable<Bool> {
        return worker.login(email: email, password: password)
    }
    
    func isRegistered(account: String) -> Observable<Bool> {
        return worker.isRegistered(account: account)
    }
    
    func signUp(username: String, password: String, sid: String, vcode: String) -> Observable<Bool> {
        return worker.signUp(username: username, password: password, sid: sid, vcode: vcode)
    }
    
    func sendVcode(to: String) -> Observable<MoveApi.VerificationCodeSend>  {
        return worker.sendVcode(to: to)
    }
    
    func checkVcode(sid: String, vcode: String) -> Observable<Bool>{
        return worker.checkVcode(sid: sid, vcode: vcode)
    }
    
    func updatePasssword(sid: String, vcode: String, email: String, password: String) -> Observable<Bool> {
        return worker.updatePasssword(sid: sid, vcode: vcode, email: email, password: password)
    }
    
    func setUserInfo(userInfo: UserInfo.Profile, newPassword: String = "") -> Observable<Bool> {
        return worker.setUserInfo(userInfo: userInfo, newPassword: newPassword)
    }
    
    func logout() -> Observable<Bool> {
        return worker.logout()
    }
}


/// User Worker Protocl
protocol UserWorkerProtocl {
    
    func login(email: String, password: String) -> Observable<Bool>
    
    func isRegistered(account: String) -> Observable<Bool>
    
    func fetchProfile() -> Observable<UserInfo.Profile>
    
    func signUp(username: String, password: String, sid: String, vcode: String) -> Observable<Bool>
    
    func sendVcode(to: String) -> Observable<MoveApi.VerificationCodeSend>
    
    func checkVcode(sid: String, vcode: String) -> Observable<Bool>
    
    func updatePasssword(sid: String, vcode: String, email: String, password: String) -> Observable<Bool>
    
    func setUserInfo(userInfo: UserInfo.Profile, newPassword: String) -> Observable<Bool>
    
    func logout() -> Observable<Bool>
}


class UserInfo {
    
    static let shared = UserInfo()
    
    var accessToken: AccessToken
    var id: String?
    var profile: Profile?
    
    private init() {
        accessToken = AccessToken()
    }
    
    struct AccessToken {
        var token: String?
        var refreshToken: String?
        var expiryAt: Date?
    }
    
    struct Profile {
        var username: String?
        var password: String?
        
        var nickname: String?
        
        var email: String?
        var phone: String?
        
        var iconUrl: String?
        var gender: String?
        var height: Int?
        var weight: Int?
        var unit_value: Int?
        var unit_weight_value: Int?
        var orientation:Int?
        var birthday: Date?
        var mtime: Date?
    }
}

extension UserInfo {
    
    func invalidate() {
        self.accessToken.expiryAt = nil
        self.accessToken.token = nil
        self.accessToken.refreshToken = nil
    }
}

extension UserInfo.AccessToken {
    
    var isValidAndNotExpired: Bool {
        guard let _ = self.token,
            let expiryAt = self.expiryAt else {
            return false
        }
        
        guard expiryAt.compare(Date()) == .orderedDescending else {
            return false
        }
        
        return true
    }
}


extension ObservableType where E == MoveApi.AccessToken {
    func catchingToken() -> Observable<UserInfo> {
        return flatMap { element -> Observable<UserInfo> in
            UserInfo.shared.accessToken.token = element.accessToken
            UserInfo.shared.accessToken.refreshToken = element.accessToken
            UserInfo.shared.accessToken.expiryAt = element.expiredAt
            UserInfo.shared.id = element.uid
            return Observable.just(UserInfo.shared)
        }
    }
}
