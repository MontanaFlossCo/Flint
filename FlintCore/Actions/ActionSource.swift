//
//  ActionSource.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 20/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The source of an action.
public enum ActionSource {
    /// The action was triggered by an event in the application itself
    case application
    
    /// The action was triggered by an INIntent request in an Intent extension
    case intent

    /// The action was triggered by the operating system passing an `NSUserActivity` to the application
    case continueActivity(type: ActivityType)
    
    /// The action was triggered by the operating system passing a URL to the application
    /// !!! TODO: Add the source URL to this
    case openURL
}
