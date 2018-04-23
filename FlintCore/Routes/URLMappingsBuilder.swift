//
//  URLMappingsBuilder.swift
//  FlintCore
//
//  Created by Marc Palmer on 29/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Builder that creates a URLMappings object.
///
/// Used to implement the URL mappings convention of a Feature, which binds schemes, domains and paths to actions.
/// An instance is passed to a closure so that Features can use a DSL-like syntax to declare their mappings.
/// The resulting `URLMappings` object is returned by the `build` function, using covariant return type inference
/// to select the correct `build` function provided by the extensions on `Feature`.
public class URLMappingsBuilder {
    var mappings = URLMappings()

    /// Create the mapping and register with the global mappings table
    private func add<F, A>(mapping: URLMapping, to actionBinding: StaticActionBinding<F, A>)
            where A.InputType: QueryParametersDecodable {

        let executor: ActionURLMappings.URLExecutor = { (queryParams: QueryParameters?, presentationRouter: PresentationRouter, source: ActionSource, completion: (ActionPerformOutcome) -> Void) in
            FlintInternal.urlMappingLogger?.debug("In URL executor for mapping \(mapping) to \(actionBinding)")
            if let state = A.InputType.init(from: queryParams) {
                let presentationRouterResult = presentationRouter.presentation(for: actionBinding, with: state)
                FlintInternal.urlMappingLogger?.debug("URL executor presentation \(presentationRouterResult) received for \(actionBinding) with state \(state)")
                switch presentationRouterResult {
                    case .appReady(let presenter):
                        actionBinding.perform(using: presenter, with: state, userInitiated: true, source: source)
                    case .unsupported:
                        FlintInternal.urlMappingLogger?.error("No presentation for mapping \(mapping) for \(actionBinding) - received .unsupported")
                    case .appCancelled, .userCancelled, .appPerformed:
                    break
                }
            } else {
                preconditionFailure("Unable to create action state \(String(describing: A.InputType.self)) from query parameters")
            }
        }
        
        FlintInternal.urlMappingLogger?.debug("Adding URL mapping \(mapping) ➡️ \(actionBinding)")
        mappings.add(mapping, actionType: actionBinding.action)
        
        // This is a bit funky doing this inside the builder, we should really take the results of the build and
        // iterate over them to add them to the actual url mapping subsystem. However this means introducing a new
        // type to contain the feature, action and executor info.
        /// !!! TODO: Introduce a new `URLMappingExecutorBinding` type and use this in `URLMappings` and return here,
        /// letting the caller iterate over the mappings and bind them to the `ActionURLMappings`
        ActionURLMappings.instance.add(mapping: mapping, for: actionBinding.feature, actionName: actionBinding.action.name, executor: executor)
    }
    
    /// Create the mapping and register with the global mappings table. Similar but not idential to above, because
    /// the type of the binding is incompatible
    private func add<F, A>(mapping: URLMapping, to actionBinding: ConditionalActionBinding<F, A>)
            where A.InputType: QueryParametersDecodable {

        let executor: ActionURLMappings.URLExecutor = { (queryParams: QueryParameters?, presentationRouter: PresentationRouter, source: ActionSource, completion: (ActionPerformOutcome) -> Void) in
            FlintInternal.urlMappingLogger?.debug("In URL executor for mapping \(mapping) to \(actionBinding)")
            if let state = A.InputType.init(from: queryParams) {
                let result = presentationRouter.presentation(for: actionBinding, with: state)
                FlintInternal.urlMappingLogger?.debug("URL executor presentation \(result) received for \(actionBinding) with state \(state)")
                switch result {
                    case .appReady(let presenter):
                        if let request = actionBinding.request() {
                            ActionSession.main.perform(request, using: presenter, with: state, userInitiated: true, source: source)
                        }
                    case .unsupported:
                        FlintInternal.urlMappingLogger?.error("No presentation for mapping \(mapping) for \(actionBinding) - received .unsupported")
                    case .appCancelled, .userCancelled, .appPerformed:
                    break
                }
            } else {
                preconditionFailure("Unable to create action state \(String(describing: A.InputType.self)) from query parameters")
            }
        }

        FlintInternal.urlMappingLogger?.debug("Adding URL mapping \(mapping) ➡️ \(actionBinding)")
        mappings.add(mapping, actionType: actionBinding.action)

        // This is a bit funky doing this inside the builder, we should really take the results of the build and
        // iterate over them to add them to the actual url mapping subsystem. However this means introducing a new
        // type to contain the feature, action and executor info.
        /// !!! TODO: Introduce a new `URLMappingExecutorBinding` type and use this in `URLMappings` and return here,
        /// letting the caller iterate over the mappings and bind them to the `ActionURLMappings`
        ActionURLMappings.instance.add(mapping: mapping, for: actionBinding.feature, actionName: actionBinding.action.name, executor: executor)
    }

    public func send<F, A>(_ path: String, to actionBinding: StaticActionBinding<F, A>, in scopes: Set<RouteScope> = [.appAny, .universalAny])
            where A.InputType: QueryParametersDecodable {
        FlintInternal.urlMappingLogger?.debug("Routing '/\(path)' in scopes \(scopes) ➡️ \(actionBinding)")
        for scope in scopes {
            let mapping = URLMapping(scope: scope, path: path)
            add(mapping: mapping, to: actionBinding)
        }
    }

    public func send<F, A>(_ path: String, to conditionalActionBinding: ConditionalActionBinding<F, A>, in scopes: Set<RouteScope> = [.appAny, .universalAny])
            where A.InputType: QueryParametersDecodable {
        FlintInternal.urlMappingLogger?.debug("Routing '/\(path)' in scopes \(scopes) ➡️ \(conditionalActionBinding)")
        for scope in scopes {
            let mapping = URLMapping(scope: scope, path: path)
            add(mapping: mapping, to: conditionalActionBinding)
        }
    }
}
