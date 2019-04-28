//
//  NoContext.swift
//  FlintCore
//
//  Created by Marc Palmer on 30/12/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A "null" state type for actions that do not require state
public struct NoInput: RouteParametersCodable, ActivityCodable, FlintLoggable {
    /// Currently we're using this because we cannot typealias action's InputType to be an optional,
    /// as this breaks generic constraints on URL mapping code. Optional (enum) cannot be used as a generic constraint
    public static let noInput = NoInput()

    private init() { }
    
    public init?(from queryParameters: RouteParameters?, mapping: URLMapping) {
    }
    
    public func encodeAsRouteParameters(for mapping: URLMapping) -> RouteParameters? {
        return nil
    }
    
    public init(activityUserInfo: [AnyHashable : Any]?) throws {
    }
    
    public func encodeForActivity() -> [AnyHashable : Any]? {
        return nil
    }
    
    public var requiredUserInfoKeys: Set<String> = []
    
    public var loggingDescription: String {
        return ""
    }

    public var loggingInfo: [String : Any]? {
        return nil
    }
}
