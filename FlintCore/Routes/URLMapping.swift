//
//  URLMapping.swift
//  FlintCore
//
//  Created by Marc Palmer on 04/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public enum URLMappingResult {
    case noMatch
    case match(mapping: URLMapping, params: [String:String])
}


/// A struct used to represent a route scope and path mapping to an action
public struct URLMapping: Hashable, Equatable, CustomDebugStringConvertible {
    let name: String
    let scope: RouteScope
    let pattern: URLPattern

    public func matches(path: String) -> URLMappingResult {
        switch pattern.match(path) {
            case .noMatch: return .noMatch
            case .match(let params): return .match(mapping: self, params: params)
        }
    }
    
    public var hashValue: Int {
        return scope.hashValue ^ pattern.hashValue
    }
    
    public static func ==(lhs: URLMapping, rhs: URLMapping) -> Bool {
        return lhs.scope == rhs.scope && lhs.pattern == rhs.pattern && lhs.name == rhs.name
    }
    
    public var debugDescription: String {
        return "/\(pattern) in \(scope) with name \(name)"
    }
}
