//
//  ActionMetadata.swift
//  FlintCore
//
//  Created by Marc Palmer on 18/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A type that tracks metadata about a single action, including its URL Mappings.
///
/// This is used for debug UIs.
///
/// - see: `FlintUI.FeatureBrowserFeature`
public class ActionMetadata {
    public let typeName: String
    public let name: String
    public let description: String
    public let inputType: Any.Type
    public let presenterType: Any.Type
    public let analyticsID: String?
    public let activityTypes: Set<ActivityEligibility>
    public private(set) var urlMappings = [String]()
    public private(set) var intentMappings = [String]()

    init<T>(_ action: T.Type) where T: Action {
        typeName = String(reflecting: action)
        name = action.name
        description = action.description
        inputType = T.InputType.self
        presenterType = T.PresenterType.self
        analyticsID = action.analyticsID
        activityTypes = action.activityTypes
    }
    
    func add(urlMapping: URLMapping) {
        urlMappings.append(urlMapping.debugDescription)
    }

    func add(intentMapping: IntentMapping) {
        intentMappings.append(String(describing: intentMapping.intentType))
    }
}
