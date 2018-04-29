//
//  FlintInternal.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 20/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Internal dependencies for Flint usage.
final class FlintInternal {

    /// The loggig topic for internal Flint Core logging that is not associated with Features
    static let coreLoggingTopic = TopicPath(["Flint", "Core"])

    /// Provides the internal logger for core bootstrapping
    static var logger: ContextSpecificLogger? = {
        return Logging.development?.contextualLogger(with: "Flint Bootstrapping", topicPath: coreLoggingTopic)
    }()

    /// Provides the internal logger for bootstrapping URL mappings
    static var urlMappingLogger: ContextSpecificLogger? = {
        return Logging.development?.contextualLogger(with: "Flint Bootstrapping", topicPath: coreLoggingTopic.appending("URL Mapping"))
    }()

}
