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
    case match(mapping: URLMapping, params: [String:String]?)
}


/// A struct used to represent a route scope and path mapping to an action
public struct URLMapping: Hashable, Equatable, CustomDebugStringConvertible {
    let name: String?
    let scope: RouteScope
    let pattern: URLPattern

    public func matches(path: String) -> URLMappingResult {
        switch pattern.match(path: path) {
            case .noMatch: return .noMatch
            case .match(let params): return .match(mapping: self, params: params)
        }
    }
    
    public func buildLink(with parameters: RouteParameters?, defaultScheme: String, defaultDomain: String) -> URL {
        var urlComponents = URLComponents()

        let generatedPath = pattern.buildPath(with: parameters?.queryParameters)
        switch scope {
            case let .app(scheme):
                urlComponents.scheme = scheme
                urlComponents.host = generatedPath
            case .appAny:
                urlComponents.scheme = defaultScheme
                urlComponents.host = generatedPath
            case let .universal(domain):
                urlComponents.scheme = "https"
                urlComponents.host = domain
                urlComponents.path = "/\(generatedPath)"
            case .universalAny:
                urlComponents.scheme = "https"
                urlComponents.host = defaultDomain
                urlComponents.path = "/\(generatedPath)"
        }
        if let routeParameters = parameters {
            let queryItems = routeParameters.queryParameters.map { key, value in return URLQueryItem(name: key, value: value) }
            urlComponents.queryItems = queryItems
        }
        return urlComponents.url!
    }
    
    public var hashValue: Int {
        return scope.hashValue /* ^ pattern.hashValue */
    }
    
    public static func ==(lhs: URLMapping, rhs: URLMapping) -> Bool {
        return lhs.scope == rhs.scope && /* lhs.pattern == rhs.pattern && */ lhs.name == rhs.name
    }
    
    public var debugDescription: String {
        return "/\(pattern) in \(scope) with name \(name ?? "<none>")"
    }
}
