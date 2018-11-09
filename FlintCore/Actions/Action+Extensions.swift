//
//  Action+Extensions.swift
//  FlintCore
//
//  Created by Marc Palmer on 11/06/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The protocol to which most application Action(s) should conform.
///
/// `Action` implementations conforming to this protocol will automatically specify that
/// they should only be dispatched in the main `ActionSession` and that all these actions must always
/// be called on the main queue, so they do not need to check they are on the main queue or use async dispatch.
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

    /// Set the default session to "main".
    /// You can override this in your conforming types if you want them to use a different namespace for logging and
    /// timelines.
    static var defaultSession: ActionSession? {
        return ActionSession.main
    }
}

/// Default implementation of the action requirements, to ease the out-of-box experience.
public extension Action {

    /// The default naming algorithm is to use the action type's name tokenized on CamelCaseBoundaries and with `Action`
    /// removed from the end. e.g. `CreateNewTweetAction` gets the name `Create New Tweet`
    static var name: String {
        let typeName = String(describing: self)
        var tokens = typeName.camelCaseToTokens()
        if tokens.last == "Action" {
            tokens.remove(at: tokens.count-1)
        }
        return tokens.joined(separator: " ")
    }

    /// The default alerts you to the fact there is no description. You should help yourself by always supplying something
    static var description: String {
        return "No description"
    }

    /// By default, all actions are included in the Timeline.
    /// Override this and return `true` if your action is not something that helps debug what the user has been doing.
    static var hideFromTimeline: Bool {
        return false
    }

    // MARK: Analytics

    /// Default is to supply no analytics ID and no analytics event will be emitted for these actions
    static var analyticsID: String? {
        return nil
    }

    /// Default behaviour is to not provide any attributes for analytics
    static func analyticsAttributes<F>(for request: ActionRequest<F, Self>) -> [String:Any?]? {
        return nil
    }

    // MARK: Activities (automatic NSUserActivity)
    
    /// By default there are no activity types, so no `NSUserActivity` will be emitted.
    static var activityTypes: Set<ActivityEligibility> {
        return []
    }

    /// The default behaviour is to return the input activity unchanged.
    ///
    /// Provide your own implementation if you need to customize the `NSUserActivity` for an Action.
    static func prepareActivity(_ activity: ActivityBuilder<Self>) {        
    }

    // MARK: Siri integrations
    
    static var suggestedInvocationPhrase: String? {
        return nil
    }
}
