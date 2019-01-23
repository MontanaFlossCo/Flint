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
    public let activityEligibility: Set<ActivityEligibility>
    public private(set) var urlMappings = [String]()
    public private(set) var intentTypeName: String?

    init<T>(_ action: T.Type) where T: Action {
        typeName = String(reflecting: action)
        name = action.name
        description = action.description
        inputType = T.InputType.self
        presenterType = T.PresenterType.self
        analyticsID = action.analyticsID
        activityEligibility = action.activityEligibility
    }
    
    func add(urlMapping: URLMapping) {
        urlMappings.append(urlMapping.debugDescription)
    }
    
    func setIntent(_ intent: FlintIntent.Type) {
        flintBugPrecondition(intentTypeName == nil, "Cannot add more than one intent to an action")
        intentTypeName = String(describing: intent)
    }
}
