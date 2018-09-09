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

/// The protocol for decoding an input value from URL route parameters.
/// Conform your input types to this to to enable execution of actions with your input type
/// when incoming URLs are parsed.
public protocol RouteParametersDecodable {
    /// Construct the type from the specified URL parameters.
    /// Implementations can use the `mapping` parameter to perform different parsing
    /// based on the kind of URL e.g. app custom URL scheme or deep linking.
    /// - param routeParameters: The dictionary of URL query parameters
    /// - param mapping: The URL mapping that the incoming URL matched
    init?(from routeParameters: RouteParameters?, mapping: URLMapping)
}

/// The protocol for encoding an input value from URL route parameters.
/// Conform your input types to this to to enable creation of links to actions with your input type.
public protocol RouteParametersEncodable {
    /// Return a dictionary of URL parameters that, when passed to `RouteParametersDecodable.init`, will
    /// reconstruct the same state of the conforming type.
    /// Implementations can use the `mapping` parameter to perform different encoding
    /// based on the kind of URL e.g. app custom URL scheme or deep linking.
    /// - param mapping: The URL mapping that is being used to create a link
    func encodeAsRouteParameters(for mapping: URLMapping) -> RouteParameters?
}

/// The protocol for encoding and decoding an input value to and from URL route parameters.
/// Conform your input types to this to to enable execution of actions with your input type
/// when incoming URLs are parsed, as well as creation of URL links to those actions.
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
