//
//  HandleIntentAction.swift
//  FlintCore
//
//  Created by Marc Palmer on 04/10/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(Intents)
import Intents
#endif

/// The input type for handling intents.
///
/// This is used to avoid having to expose hard dependencies on `INIntent` in our public facing APIs for
/// platforms or apps that do not import Intents.
struct FlintIntentWrapper: FlintLoggable {
#if canImport(Intents)
    let intent: INIntent
#endif
}

/// Dispatch the appropriate action for a given intent.
///
/// Call this from within Intent extensions to perform the correct action.
final class DispatchIntentAction: IntentAction {
    typealias InputType = FlintIntentWrapper
    typealias PresenterType = IntentResultPresenter
    
    enum IntentActionError: Error {
        case noMappingFound
    }

    static func perform(context: ActionContext<FlintIntentWrapper>, presenter: IntentResultPresenter, completion: Completion) -> Completion.Status {
        // Look up the executor by type
        guard let mapping = IntentMappings.instance.mapping(for: type(of: context.input.intent)) else {
            return completion.completedSync(.failure(error: IntentActionError.noMappingFound))
        }

        // Call it
        return mapping.performAction(for: context.input.intent, presenter: presenter, completion: completion)
    }
}
