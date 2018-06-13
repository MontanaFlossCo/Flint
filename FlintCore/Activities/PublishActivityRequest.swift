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
    let activityCreator: () -> NSUserActivity?
    let appLink: URL?

    var description: String {
        return "Action: \(actionName)"
    }
    
    var debugDescription: String {
        return "PublishActivityRequest for action: \(actionName) of feature \(feature). URL: \(appLink?.description ?? "nil")"
    }
}

