//
//  ActivityCodable.swift
//  FlintCore
//
//  Created by Marc Palmer on 14/06/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The error type for reporting userInfo related failures
enum ActivityCodableError {
    /// Indicates that one or more required userInfo keys were missing
    case missingKeys(keys: Set<String>)
    /// Indicates that one or more required userInfo keys had an invalid value
    case invalidValues(keys: Set<String>)
}

/// Action input types can conform to this protocol to automatically
/// supply the `userInfo` for NSUserActivity with the Activities feature.
public protocol ActivityCodable {
    /// Conforming types must initialise themselves fully from the userInfo supplied, or throw an error.
    init(activityUserInfo: [AnyHashable:Any]?) throws
    
    /// Implementations must encode all state required to reconstruct the type again from userInfo of an `NSUserActivity`
    /// using userInfo compatible foundation types.
    func encodeForActivity() -> [AnyHashable:Any]?

    /// Implementations must return a list of all the userInfo keys required to reconstruct the type again from userInfo of an `NSUserActivity`
    /// at a later point. Only these keys are guaranteed to be persisted and used for machine learning for suggestions etc.
    var requiredUserInfoKeys: Set<String> { get }
}
