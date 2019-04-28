//
//  ContextualLoggerFactory.swift
//  FlintCore
//
//  Created by Marc Palmer on 31/12/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The low level interface for getting a logger.
///
/// This is the application-facing interface for logging, which will filter and if necessary prepare
/// log entries for the underlying logging implementation.
///
/// - note: Flint supports log levels *per topic path* (e.g. by Feature) even without setting one or more focused features.
///
/// - see: `DefaultLoggerFactory`
public protocol ContextualLoggerFactory: AnyObject {
    /// The log level. This can be changed at runtime.
    var level: LoggerLevel { get set }
    
    /// A symbolic name for the factory
    var name: String { get }

    /// Set a log level for a specific topic path. Set to nil to remove specific logging for that topic.
    func setLevel(for topic: TopicPath, to level: LoggerLevel?)

    /// Get a contextual logger for the given context
    func contextualLogger(with context: LogEventContext) -> ContextSpecificLogger

    /// Get a contextual logger for a non-Flint context where you still need to log things but the code is not
    /// aware of Action(s) and action dispatch. This at least allows non-Flint code
    /// to be passed loggers that have some contextual information
    func contextualLogger(activity: String, topicPath: TopicPath) -> ContextSpecificLogger
    
    /// Internal function for adding outputs at runtime to facilitate Focus.
    func add(output: LoggerOutput)
}
