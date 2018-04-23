//
//  URLMapping.swift
//  FlintCore
//
//  Created by Marc Palmer on 04/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A struct used to represent a route scope and path mapping to an action
public struct URLMapping: Hashable, Equatable, CustomDebugStringConvertible {
    let scope: RouteScope
    let path: String

    public var hashValue: Int {
        return scope.hashValue ^ path.hashValue
    }
    
    public static func ==(lhs: URLMapping, rhs: URLMapping) -> Bool {
        return lhs.scope == rhs.scope && lhs.path == rhs.path
    }
    
    public var debugDescription: String {
        return "/\(path) in \(scope)"
    }
}
