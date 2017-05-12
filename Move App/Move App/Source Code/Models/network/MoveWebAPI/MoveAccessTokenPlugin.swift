//
//  MoveAccessTokenPlugin.swift
//  Move App
//
//  Created by Jiang Duan on 17/2/7.
//  Copyright © 2017年 TCL Com. All rights reserved.
//

import Foundation
import Moya

struct MoveAccessTokenPlugin: PluginType {
    
    /// The access token to be applied in the header.
    public var token: String {
        get {
            return UserInfo.shared.accessToken.token ?? ""
        }
    }
    
    private var authVal: String {
        let uidData = UserInfo.shared.id?.data(using: String.Encoding.utf8)
        return "\(MoveApi.apiKey);token=\(token);\(AuthenCryptor.token(withUid: uidData))"
    }
    
    /**
     Prepare a request by adding an authorization header if necessary.
     
     - parameters:
     - request: The request to modify.
     - target: The target of the request.
     - returns: The modified `URLRequest`.
     */
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        if let authorizable = target as? AccessTokenAuthorizable, authorizable.shouldAuthorize == false {
            return request
        }
        
        var request = request
        if let strAuth = request.allHTTPHeaderFields?["Authorization"] {
            let uidData = UserInfo.shared.id?.data(using: String.Encoding.utf8)
            request.setValue("\(strAuth);token=\(token);\(AuthenCryptor.token(withUid: uidData))", forHTTPHeaderField: "Authorization")
            
        } else {
            request.setValue(authVal, forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
}
