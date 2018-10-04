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
    
    static func perform(context: ActionContext<FlintIntentWrapper>, presenter: IntentResultPresenter, completion: Completion) -> Completion.Status {
        // Look up the executor by type
        // Call it
        // return the result
        return completion.completedSync(.success)
    }
}
