//
//  ContextSpecificLogger.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 16/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The is the high level logger interface that uses the same context for all events, for passing to actions and other
/// subsystems where the user's feature context is known.
///
/// You obtain one of these from a `ContextualLoggerFactory`, although typically Flint will automatically provide these
/// to your `Action`(s) in the `ActionContext`.
public protocol ContextSpecificLogger: AnyObject {
    var level: LoggerLevel { get }
    
    /// The name of the logger factor that created this logger, e.g. "production"
    var ownerName: String { get }
    
    /// The context for this logger. Includes the Flint `ActionSession` name and the `TopicPath` of the event (this is
    /// usually based on the Feature & Action calling into this logger).
    var context: LogEventContext { get }

    /// Called to log `info` level events
    func info(_ content: @escaping @autoclosure () -> String)

    /// Called to log `error` level events
    func error(_ content: @escaping @autoclosure () -> String)

    /// Called to log `warning` level events
    func warning(_ content: @escaping @autoclosure () -> String)

    /// Called to log `debug` level events
    func debug(_ content: @escaping @autoclosure () -> String)
}
