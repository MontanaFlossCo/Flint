//
//  URLMapped.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 19/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Features must adopt this protocol if they support URL mappings, and define
/// the mappings from URLs to actions.
///
/// There is support for multiple custom app URL schemes and multiple associated domains.
public protocol URLMapped {

    /// Call to initialise `urlMappings` using the routes DSL. You pass a closure that receives the builder instance,
    /// and call functions on the builder to define how incoming URLs route to your feature's actions.
    ///
    /// Example:
    ///
    /// ```
    /// static func urlMappings(routes: URLMappingsBuilder) {
    ///     routes.send("create", to: createNew)
    ///     routes.send("open", to: openDocument)
    /// }
    /// ```
    ///
    /// - see: `URLMappingsBuilder` which supports routing to specific scopes and multiple scopes
    static func urlMappings(routes routeBuilder: URLMappingsBuilder)
    
}


