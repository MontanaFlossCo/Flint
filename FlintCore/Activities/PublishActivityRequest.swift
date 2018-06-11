//
//  PublishActivityRequest.swift
//  FlintCore
//
//  Created by Marc Palmer on 20/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The information required to publish
struct PublishActivityRequest: CustomStringConvertible, CustomDebugStringConvertible {
    let actionName: String
    let feature: FeatureDefinition.Type
    let userInfoFunction: () -> [AnyHashable: Any]?
    let requiredUserInfoKeysFunction: () -> Set<String>?
    let prepareFunction: (_ activity: NSUserActivity) -> NSUserActivity?
    let activityTypes: Set<ActivityEligibility>
    let appLink: URL?

    var description: String {
        return "Action: \(actionName)"
    }
    
    var debugDescription: String {
        let activities = activityTypes.map({ String(reflecting: $0) }).joined(separator: ", ")
        return "PublishActivityRequest for action: \(actionName) of feature \(feature). Activity types: \(activities). URL: \(appLink?.description ?? "nil")"
    }
}

