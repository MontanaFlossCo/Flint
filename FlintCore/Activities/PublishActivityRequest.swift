//
//  PublishActivityRequest.swift
//  FlintCore
//
//  Created by Marc Palmer on 20/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The information required to publish
struct PublishActivityRequest: FlintLoggable {
    let actionName: String
    let feature: FeatureDefinition.Type
    let activityCreator: () throws -> NSUserActivity? 
    let appLink: URL?

    var loggingDescription: String {
        return "Action: \(actionName)"
    }
    
    var loggingInfo: [String:Any]? {
        return [
            "action": actionName,
            "feature": feature.description,
            "url": appLink?.description ?? "nil"
        ]
    }
}

