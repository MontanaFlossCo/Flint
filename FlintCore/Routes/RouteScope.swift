//
//  RouteScope.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 20/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A type representing a single URL scope.
///
/// URL scopes can be for application custom schemes e.g. x-hobson://something, or universal linking / associated domains,
/// of the form https://hobsonapp.com/something. The scope is just the "context" part, e.g. "x-hobson" or "hobsonapp.com"
public enum RouteScope: Hashable, CustomDebugStringConvertible {
    /// Indicates the route applies to any and all custom URL schemes the app has declared in Info.plist
    case appAny

    /// Indicates the route applies to a specific custom scheme declared in Info.plist
    case app(scheme: String)

    /// Indicates the route applies to any and all universal domains declared on your app
    case universalAny

    /// Indicates the route applies to a specific universal domains declared on your app
    case universal(domain: String)
    
    /// - return: `true` if this route scope is for any kind of universal domain link
    public var isUniversal: Bool {
        if case .universal = self {
            return true
        } else {
            return self == .universalAny
        }
    }
    
    /// - return: `true` if this route scope is for any kind of custom URL scheme
    public var isApp: Bool {
        if case .app = self {
            return true
        } else {
            return self == .appAny
        }
    }
    
#if swift(>=4.2)
    public func hash(into hasher: inout Hasher) {
        let value: Int
        switch self {
            case .appAny: value = 0
            case .universalAny: value = 1
            case .app(let scheme): value = scheme.hashValue
            case .universal(let domain): value = domain.hashValue
        }
        hasher.combine(value)
    }
#else
    public var hashValue: Int {
        switch self {
            case .appAny: return 0
            case .universalAny: return 1
            case .app(let scheme): return scheme.hashValue
            case .universal(let domain): return domain.hashValue
        }
    }
#endif

    public static func ==(lhs: RouteScope, rhs: RouteScope) -> Bool {
        switch (lhs, rhs) {
            case (.appAny, .appAny): return true
            case (.universalAny, .universalAny): return true
            case (.app(let lhsScheme), .app(let rhsScheme)): return lhsScheme == rhsScheme
            case (.universal(let lhsDomain), .universal(let rhsDomain)): return lhsDomain == rhsDomain
            default: return false
        }
    }
    
    public var debugDescription: String {
        switch self {
            case .appAny: return ".appAny"
            case .app(let scheme): return ".app(\(scheme))"
            case .universalAny: return ".universalAny"
            case .universal(let domain): return ".universal(\(domain))"
        }
    }
}
