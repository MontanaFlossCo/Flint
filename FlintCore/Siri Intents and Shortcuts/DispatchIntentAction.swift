//
//  HandleIntentAction.swift
//  FlintCore
//
//  Created by Marc Palmer on 04/10/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Dispatch the appropriate action for a given intent.
///
/// Called from within Intent extensions to perform the correct action.
///
/// - note: You should not need to call this, see `Flint.performIntent` instead.
final class DispatchIntentAction: IntentBackgroundAction {
    typealias InputType = FlintIntentWrapper
    typealias PresenterType = IntentResultPresenter

    enum IntentActionError: Error {
        case invalidInputFromIntent
        case noMappingFound
        case noIntentSupplied
    }

    static func perform(context: ActionContext<FlintIntentWrapper>, presenter: IntentResultPresenter, completion: Completion) -> Completion.Status {
        // Look up the executor by type
        guard let mapping = IntentMappings.shared.mapping(for: type(of: context.input.intent)) else {
            return completion.completedSync(.failureWithFeatureTermination(error: IntentActionError.noMappingFound))
        }

        // Call it
        /// !!! TODO: Proxy this and convert it to a feature terminating result
        return mapping.performAction(for: context.input.intent, presenter: presenter, completion: completion)
    }
}
