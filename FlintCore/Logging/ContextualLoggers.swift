//
//  Logs.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 21/07/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Provides access to the context specific loggers for a feature or action
public struct ContextualLoggers {
    /// The development logger, if any
    public let development: ContextSpecificLogger?

    /// The production logger, if any
    public let production: ContextSpecificLogger?
    
    /// Used internally to create the set of loggers
    init(development: ContextSpecificLogger?, production: ContextSpecificLogger?) {
        self.development = development
        self.production = production
    }
}
