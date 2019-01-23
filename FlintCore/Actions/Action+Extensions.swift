//
//  Action+Extensions.swift
//  FlintCore
//
//  Created by Marc Palmer on 11/06/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(Intents)
import Intents
#endif

/// Default implementation of the standard action requirements, to ease the out-of-box experience.
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
}

/// Default implementation of the analytics requirements, to ease the out-of-box experience.
public extension Action {
    /// Default is to supply no analytics ID and no analytics event will be emitted for these actions
    static var analyticsID: String? {
        return nil
    }

    /// Default behaviour is to not provide any attributes for analytics
    static func analyticsAttributes<F>(for request: ActionRequest<F, Self>) -> [String:Any?]? {
        return nil
    }
}

/// Default implementation of the activities requirements, to ease the out-of-box experience.
public extension Action {
    /// By default there are no activity types, so no `NSUserActivity` will be emitted.
    static var activityEligibility: Set<ActivityEligibility> {
        return []
    }

    /// The default behaviour is to return the input activity unchanged.
    ///
    /// Provide your own implementation if you need to customize the `NSUserActivity` for an Action.
    static func prepareActivity(_ activity: ActivityBuilder<Self>) {        
    }
}

/// Default implementation of the Siri and Intents requirements, to ease the out-of-box experience.
public extension Action {
    public static var suggestedInvocationPhrase: String? {
        return nil
    }

#if canImport(Intents)
    /// Implement this function if the Action supports a Siri Intent for Shortcuts. This is used to register
    /// a shortcut intent with Siri if you have the `IntentShortcutDonationFeature` enabled.
    @available(iOS 12, *)
    static func associatedIntents(for input: InputType) -> [FlintIntent]? {
        return nil
    }
#endif
}
