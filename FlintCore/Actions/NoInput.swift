//
//  NoContext.swift
//  FlintCore
//
//  Created by Marc Palmer on 30/12/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A "null" state type for actions that do not require state
public struct NoInput: QueryParametersCodable, CustomStringConvertible, CustomDebugStringConvertible {
    /// Currently we're using this because we cannot typealias action's InputType to be an optional,
    /// as this breaks generic constraints on URL mapping code. Optional (enum) cannot be used as a generic constraint
    public static let none = NoInput()

    private init() { }
    
    public init?(from queryParameters: QueryParameters?) {
    }
    
    public func encodeAsQueryParameters() -> QueryParameters? {
        return nil
    }
    
    public var description: String {
        return ""
    }

    public var debugDescription: String {
        return ""
    }
}
