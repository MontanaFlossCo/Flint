//
//  ActivityCodable.swift
//  FlintCore
//
//  Created by Marc Palmer on 14/06/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Action input types can conform to this protocol to automatically
/// supply the `userInfo` for NSUserActivity with the Activities feature.
public protocol ActivityCodable {
    init?(activityUserInfo: [AnyHashable:Any]?) throws
    
    func encodeForActivity() -> [AnyHashable:Any]?

    var requiredUserInfoKeys: Set<String> { get }
}
