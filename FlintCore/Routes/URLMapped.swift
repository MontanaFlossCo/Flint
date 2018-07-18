//
//  URLMapped.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 19/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Features must adopt this protocol if they support URL mappings, and define
/// the routes that map from URLs to actions.
///
/// There is support for multiple custom app URL schemes and multiple associated domains, URL wildcards and named
/// variables in the path components.
public protocol URLMapped {

    /// Called by Flint to initialise `urlMappings` using the routes builder. Your function receives the
    /// builder instance and must call functions on the builder to define how incoming URLs route to your feature's actions.
    ///
    /// URL routes support basic wildcards and paths containing named parameters that are extracted as values passed to
    /// your action input.
    ///
    /// Any query parameters from the URL are extracted and combined with named path parameters
    /// you define in mappings, and passed to your action input type that must conform to `RouteParametersCodable`
    ///
    /// Example:
    ///
    /// ```
    /// static func urlMappings(routes: URLMappingsBuilder) {
    ///     // "/create" for any source will go to createNew
    ///     routes.send("create", to: createNew)
    ///
    ///     // "x-legacy://open-doc" will go to openDocument
    ///     routes.send("open-doc", to: openDocument, in: [.app(scheme: "x-legacy"])
    ///
    ///     // "https://yourapp.com/open" and any custom scheme for "/open"  will go to openDocument
    ///     routes.send("open", to: openDocument, in: [.appAny, .universal(domain: "yourapp.com")])
    ///
    ///     // Match "/profile/" with any other path components after it e.g. "/profile/avatar" on any source will go to showProfile
    ///     routes.send("profile/**", to: showProfile)
    ///
    ///     // Match "/blog/*/*/*/post-name-here" with any year/month/day values, extracting the post name ("name-here") as a route parameter passed
    ///     to the input, routing to the action showPost
    ///     routes.send("blog/*/*/*/post-$(postname)", to: showPost)
    /// }
    /// ```
    /// - param routes: A builder that you use to define the URL routes supported by your feature.
    ///
    /// - see: `URLMappingsBuilder` for full details
    static func urlMappings(routes: URLMappingsBuilder)
    
}


