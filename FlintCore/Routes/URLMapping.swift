//
//  URLMapping.swift
//  FlintCore
//
//  Created by Marc Palmer on 04/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public struct URLMappingResult {
    let mapping: URLMapping
    let parameters: [String:String]?
}


/// A struct used to represent a route scope and path mapping to an action
public struct URLMapping: Hashable, Equatable, CustomStringConvertible, CustomDebugStringConvertible {
    let name: String?
    let scope: RouteScope
    let pattern: AnyURLPattern

    public init<PatternType>(name: String?, scope: RouteScope, pattern: PatternType) where PatternType: URLPattern {
        self.name = name
        self.scope = scope
        self.pattern = AnyURLPattern(pattern: pattern)
    }

    public func matches(path: String) -> URLMappingResult? {
        switch pattern.match(path: path) {
            case .none: return nil
            case .some(let params): return URLMappingResult(mapping: self, parameters: params)
        }
    }
    
    public func buildLink(with parameters: RouteParameters?, defaultPrefix: String) -> URL {
        var urlComponents = URLComponents()

        guard let generatedPath = pattern.buildPath(with: parameters) else {
            flintUsageError("Unable to generate link, pattern \(pattern) cannot be used to generate a link from \(String(describing: parameters))")
        }
        switch scope {
            case let .app(scheme):
                urlComponents.scheme = scheme
                urlComponents.host = generatedPath
            case .appAny:
                urlComponents.scheme = defaultPrefix
                urlComponents.host = generatedPath
            case let .universal(domain):
                urlComponents.scheme = "https"
                urlComponents.host = domain
                urlComponents.path = "/\(generatedPath)"
            case .universalAny:
                urlComponents.scheme = "https"
                urlComponents.host = defaultPrefix
                urlComponents.path = "/\(generatedPath)"
        }
        if let routeParameters = parameters {
            let queryItems = routeParameters.map { key, value in return URLQueryItem(name: key, value: value) }
            urlComponents.queryItems = queryItems
        }
        return urlComponents.url!
    }
    
#if swift(>=4.2)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(scope.hashValue ^ pattern.urlPattern.hashValue)
    }
#else
    public var hashValue: Int {
        return scope.hashValue ^ pattern.urlPattern.hashValue
    }
#endif

    public static func ==(lhs: URLMapping, rhs: URLMapping) -> Bool {
        return lhs.scope == rhs.scope &&
            lhs.pattern == rhs.pattern &&
            lhs.name == rhs.name
    }
    
    public var description: String {
        var result = "/\(pattern.urlPattern)"
        switch scope {
            case .appAny: result.append(" in all app schemes")
            case .universalAny: result.append(" in all associated domains")
            case .app(let scheme): result.append(" in app scheme \(scheme)")
            case .universal(let domain): result.append(" in associated domain \(domain)")
        }
        if let name = name {
            result.append(" with name \(name)")
        }
        return result
    }
    
    public var debugDescription: String {
        return "/\(pattern.urlPattern) in \(scope) with name \(name ?? "<none>")"
    }
}
