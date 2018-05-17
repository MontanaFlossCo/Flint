//
//  QueryParametersCodable.swift
//  FlintCore
//
//  Created by Marc Palmer on 29/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// !!! TODO: These need to change to URLRepresentable or similar, so that custom path and query param encodings can be
/// applied based on whether an action is being encoded to a custom app scheme or a deep universal link e.g.:
///
/// x-app://open/?id=34534534
///
/// this is fine but the same link to share via e.g...
///
/// www.my-x-app.com/user/documents/open/34534534
///
/// That is more the kind of thing we want, where we take the prefix and add different path elements and maybe encode the
/// other parts of the input state differently because it is a public URL.

public struct RouteParameters {
    let queryParameters: [String:String]
    let routePath: [String]
}

public protocol RouteParametersDecodable {
    init?(from routeParameters: RouteParameters?, mapping: URLMapping)
}

public protocol RouteParametersEncodable {
    func encodeAsRouteParameters(for mapping: URLMapping) -> RouteParameters?
}

public typealias RouteParametersCodable = RouteParametersDecodable & RouteParametersEncodable

