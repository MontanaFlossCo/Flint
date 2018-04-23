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
public enum RouteScope: Hashable, Equatable, CustomDebugStringConvertible {
    case appAny
    case app(scheme: String)
    case universalAny
    case universal(domain: String)
    
    public var isUniversal: Bool {
        if case .universal = self {
            return true
        } else {
            return self == .universalAny
        }
    }
    
    public var isApp: Bool {
        if case .app = self {
            return true
        } else {
            return self == .appAny
        }
    }
    
    public var hashValue: Int {
        switch self {
            case .appAny: return 0
            case .universalAny: return 1
            case .app(let scheme): return scheme.hashValue
            case .universal(let domain): return domain.hashValue
        }
    }
    
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
