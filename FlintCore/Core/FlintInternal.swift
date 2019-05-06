//
//  FlintInternal.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 20/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Internal dependencies for Flint usage.
public final class FlintInternal {

    /// The loggig topic for internal Flint Core logging that is not associated with Features
    public static let coreLoggingTopic = TopicPath(["Flint", "Core"])

    /// Provides the internal logger for core bootstrapping
    static var logger: ContextSpecificLogger? = {
        return Logging.development?.contextualLogger(activity: "Flint Bootstrapping", topicPath: coreLoggingTopic)
    }()

    /// Provides the internal logger for bootstrapping URL mappings
    static var urlMappingLogger: ContextSpecificLogger? = {
        return Logging.development?.contextualLogger(activity: "Flint Bootstrapping", topicPath: coreLoggingTopic.appending("URL Mapping"))
    }()

    /// - return: The number of features (including nested) that are provided by Flint in `FlintFeatures`
    static var internalFeaturesCount: Int {
        func countSubfeatures(_ group: FeatureGroup.Type) -> Int {
            var result: Int = group.subfeatures.count
            let groupSubfeatures = group.subfeatures.compactMap({ $0 as? FeatureGroup.Type })
            groupSubfeatures.forEach { result += countSubfeatures($0) }
            return result
        }
        return countSubfeatures(FlintFeatures.self) + 1 // One for FlintFeatures itself
    }
}
