//
//  RouteParametersCodable.swift
//  FlintCore
//
//  Created by Marc Palmer on 29/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The type for parameters that can be decoded and encoded for a URL.
public typealias RouteParameters = [String:String]

/// The protocol to adopt to support creating an input type from an incoming URL that matched the route
public protocol RouteParametersDecodable {
    init?(from routeParameters: RouteParameters?, mapping: URLMapping)
}

public protocol RouteParametersEncodable {
    func encodeAsRouteParameters(for mapping: URLMapping) -> RouteParameters?
}

public typealias RouteParametersCodable = RouteParametersDecodable & RouteParametersEncodable

protocol FlintOptionalProtocol {
    var isNil: Bool { get }
}

extension Optional: FlintOptionalProtocol {
    var isNil: Bool {
        if case .none = self {
            return true
        } else {
            return false
        }
    }
}

/// Add support for optional input types that are URL mapped!
///
/// This makes my head explode that we can even do this. Kudos to the Swift team.
extension Optional: RouteParametersCodable where Wrapped: RouteParametersCodable {
    public init?(from routeParameters: RouteParameters?, mapping: URLMapping) {
        guard let result = Wrapped.init(from: routeParameters, mapping: mapping) else {
            self = .none
            return
        }
        self = .some(result)
    }
    
    public func encodeAsRouteParameters(for mapping: URLMapping) -> RouteParameters? {
        // We still want to be encodable even if we're nil, as we are by definition an optional input
        guard case let .some(wrapped) = self else {
            return [:]
        }
        return wrapped.encodeAsRouteParameters(for: mapping)
    }
}
