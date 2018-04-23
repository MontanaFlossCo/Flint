//
//  ActionDispatchLogging
//  FlintCore
//
//  Created by Marc Palmer on 15/10/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// This is a simple action dispatch observer that will log the start and end of every action execution.
///
/// To add this to aid debugging, just add the following code:
///
/// ```
/// Flint.dispatcher.add(observer: ActionLoggingDispatchObserver.instance)
/// ```
public class ActionLoggingDispatchObserver: ActionDispatchObserver {
    public static var instance = ActionLoggingDispatchObserver()
    
    private init() {
    }
    
    public func actionWillBegin<F, A>(_ request: ActionRequest<F, A>) {
        request.context.logs.development?.debug("Starting")
    }
    
    public func actionDidComplete<F, A>(_ request: ActionRequest<F, A>, outcome: ActionPerformOutcome) {
        request.context.logs.development?.debug("Completed (\(outcome))")
    }

}
