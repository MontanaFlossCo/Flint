//
//  URLMappingsBuilder.swift
//  FlintCore
//
//  Created by Marc Palmer on 29/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Builder that creates a URLMappings object, containing all the mappings for a single feature.
///
/// This is used to implement the URL mappings convention of a Feature, which binds schemes, domains and paths to actions.
/// An instance is passed to a closure so that Features can use a DSL-like syntax to declare their mappings.
///
/// The resulting `URLMappings` object is returned by the `build` function, using covariant return type inference
/// to select the correct `build` function provided by the extensions on `Feature`.
public class URLMappingsBuilder {
    var mappings = URLMappings()

    /// Define a new URL route from the specified pattern to the action binding of a `Feature`.
    ///
    /// Use this to define what URLs will invoke the action, and in which scopes. URL routes support simple wildcards and
    /// named path elements that can be extracted into route parameters from which the input for the action will be reconstructed.
    ///
    /// Pattern can be of the form:
    ///
    /// * "account/profile/view"
    /// * "account/*/view" (match anything at the 2nd path component)
    /// * "account/**" (match everything after /)
    /// * "account/$(id)" — extract the second path component as "id" for parameters, matching only two-component urls
    /// * "account/$(id)/view" — extract the second path component as "id" for parameters, matching only three-component urls
    /// * "account/junk$(id)here/view" — extract the second path component part between "junk" and "here" as "id" for parameters, matching only three-component urls
    /// * "account/junk$(id)here/*/view" — combining some of the above
    /// * "*/$(id)" — any two-component path, with the second part used as "id" parameter
    /// * "*/$(id)/view" — any three-component path, with the second part used as "id" parameter, only matching when followed by "/view"
    ///
    /// Any trailing query parameters on the URL following the optional "?" will be extracted first as route parameters.
    /// Any named path parameters in the route pattern will supercede these. You can have as many named parameters as you require.
    ///
    /// - param pattern: A URL matching pattern that will match the path only (ignoring query parameters).
    /// A leading `/` is optional, and implied
    /// - param actionBinding: The action binding to use when performing the action for the URL
    /// - param scopes: A set of scopes to which the route applies. You can supply as many as you require. The default is `[.appAny, .universalAny]`
    /// - param name: An optional value that if supplied will allow your `RouteParametersDecodable` action input type
    /// to tell which route it is being used with, so that you can e.g. customise the input type's values based on the incoming
    /// URL used. For example you might set an `isFromPublicLink = true` property on the input if the route name was "public-web-profile"
    public func send<FeatureType, ActionType>(_ pattern: String, to actionBinding: StaticActionBinding<FeatureType, ActionType>, in scopes: Set<RouteScope> = [.appAny, .universalAny], name: String? = nil)
            where ActionType.InputType: RouteParametersDecodable {
        FlintInternal.urlMappingLogger?.debug("Routing '\(pattern)' in scopes \(scopes) ➡️ \(actionBinding) with name: \(name ?? "<none>")")
        for scope in scopes {
            let mapping = createURLMapping(named: name, for: pattern, in: scope)
            add(mapping: mapping, to: actionBinding)
        }
    }

    /// Define a new URL route from the specified pattern to the action binding of a `ConditionalFeature`.
    ///
    /// - param pattern: The URL pattern to match. A leading `/` is optional, and implied
    /// - param conditionalActionBinding: The action binding the URL should perform
    ///
    /// - see: `send` for static action bindings.
    public func send<FeatureType, ActionType>(_ pattern: String, to conditionalActionBinding: ConditionalActionBinding<FeatureType, ActionType>, in scopes: Set<RouteScope> = [.appAny, .universalAny], name: String? = nil)
            where ActionType.InputType: RouteParametersDecodable {
        FlintInternal.urlMappingLogger?.debug("Routing '\(pattern)' in scopes \(scopes) ➡️ \(conditionalActionBinding)")
        for scope in scopes {
            let mapping = createURLMapping(named: name, for: pattern, in: scope)
            add(mapping: mapping, to: conditionalActionBinding)
        }
    }

    private func createURLMapping(named name: String?, for pattern: String, in scope: RouteScope) -> URLMapping {
        let trimmedPattern = pattern.starts(with: "/") ? String(pattern.dropFirst()) : pattern
        let mapping = URLMapping(name: name, scope: scope, pattern: RegexURLPattern(urlPattern: "/\(trimmedPattern)"))
        return mapping
    }

    /// Create the mapping and register with the global mappings table
    private func add<FeatureType, ActionType>(mapping: URLMapping, to actionBinding: StaticActionBinding<FeatureType, ActionType>)
            where ActionType.InputType: RouteParametersDecodable {

        let executor: URLExecutor = { (queryParams: RouteParameters?, presentationRouter: PresentationRouter, source: ActionSource, completion: (ActionPerformOutcome) -> Void) in
            FlintInternal.urlMappingLogger?.debug("In URL executor for mapping \(mapping) to \(actionBinding)")
      
            if let input = ActionType.InputType.init(from: queryParams, mapping: mapping) {

                let presentationRouterResult = presentationRouter.presentation(for: actionBinding, input: input)

                FlintInternal.urlMappingLogger?.debug("URL executor presentation \(presentationRouterResult) received for \(actionBinding) with input \(input)")
                switch presentationRouterResult {
                    case .appReady(let presenter):
                        actionBinding.perform(input: input, presenter: presenter, userInitiated: true, source: source)
                    case .unsupported:
                        FlintInternal.urlMappingLogger?.error("No presentation for mapping \(mapping) for \(actionBinding) - received .unsupported")
                    case .appCancelled, .userCancelled, .appPerformed:
                    break
                }

            } else {
                flintUsageError("Unable to create action state \(String(describing: ActionType.InputType.self)) from query parameters")
            }
        }
        
        FlintInternal.urlMappingLogger?.debug("Adding URL mapping \(mapping) ➡️ \(actionBinding)")
        mappings.add(mapping, actionType: ActionType.self)
        
        // This is a bit funky doing this inside the builder, we should really take the results of the build and
        // iterate over them to add them to the actual url mapping subsystem. However this means introducing a new
        // type to contain the feature, action and executor info.
        /// !!! TODO: Introduce a new `URLMappingExecutorBinding` type and use this in `URLMappings` and return here,
        /// letting the caller iterate over the mappings and bind them to the `ActionURLMappings`
        ActionURLMappings.instance.add(mapping: mapping, for: FeatureType.self, actionName: ActionType.name, executor: executor)
    }
    
    /// Create the mapping and register with the global mappings table. Similar but not idential to above, because
    /// the type of the binding is incompatible
    private func add<FeatureType, ActionType>(mapping: URLMapping, to actionBinding: ConditionalActionBinding<FeatureType, ActionType>)
            where ActionType.InputType: RouteParametersDecodable {

        let executor: URLExecutor = { (queryParams: RouteParameters?, presentationRouter: PresentationRouter, source: ActionSource, completion: (ActionPerformOutcome) -> Void) in
            FlintInternal.urlMappingLogger?.debug("In URL executor for mapping \(mapping) to \(actionBinding)")
            if let input = ActionType.InputType.init(from: queryParams, mapping: mapping) {
                let result = presentationRouter.presentation(for: actionBinding, input: input)
                FlintInternal.urlMappingLogger?.debug("URL executor presentation \(result) received for \(actionBinding) with input \(input)")
                switch result {
                    case .appReady(let presenter):
                        if let request = actionBinding.request() {
                            request.perform(input: input, presenter: presenter, userInitiated: true, source: source)
                        }
                    case .unsupported:
                        FlintInternal.urlMappingLogger?.error("No presentation for mapping \(mapping) for \(actionBinding) - received .unsupported")
                    case .appCancelled, .userCancelled, .appPerformed:
                    break
                }
            } else {
                flintUsageError("Unable to create action state \(String(describing: ActionType.InputType.self)) from query parameters")
            }
        }

        FlintInternal.urlMappingLogger?.debug("Adding URL mapping \(mapping) ➡️ \(actionBinding)")
        mappings.add(mapping, actionType: ActionType.self)

        // This is a bit funky doing this inside the builder, we should really take the results of the build and
        // iterate over them to add them to the actual url mapping subsystem. However this means introducing a new
        // type to contain the feature, action and executor info.
        /// !!! TODO: Introduce a new `URLMappingExecutorBinding` type and use this in `URLMappings` and return here,
        /// letting the caller iterate over the mappings and bind them to the `ActionURLMappings`
        ActionURLMappings.instance.add(mapping: mapping, for: FeatureType.self, actionName: ActionType.name, executor: executor)
    }
}
