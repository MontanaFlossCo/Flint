//
//  UIAction.swift
//  FlintCore
//
//  Created by Marc Palmer on 24/09/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Actions that are performed in the main session and on the main dispatch queue should conform to this 
public protocol UIAction: Action {
}

public extension UIAction {
    /// By default the dispatch queue that all actions are called on is `main`.
    /// They will be called synchronously if the caller is already on the same queue, and asynchronously
    /// only if the caller is not already on the same queue.
    ///
    /// - see: `ActionSession.callerQueue` because that determines which queue the action can be performed from,
    /// and the session will prevent calls from other queues. This does not have to be the same as the Action's queue.
    static var queue: DispatchQueue {
        return .main
    }


    static var defaultSession: ActionSession? {
        return ActionSession.main
    }
}
