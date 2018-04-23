//
//  DefaultLoggerFactory.swift
//  FlintCore
//
//  Created by Marc Palmer on 31/12/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The defaut Focus-aware filtering logger factory.
///
/// This creates contextual loggers that support Focus to restrict logging to specific features at runtime.
///
/// Note that Flint supports log levels *per topic path* (e.g. by Feature) even without setting one or more focused features.
///
/// This means you can run all your subsystems at `info` level but turn your app loggic to `debug` for example.
public class DefaultLoggerFactory: ContextualLoggerFactory, DebugReportable {
    public static let noSessionName = "N/A"
    
    public var level: LoggerLevel {
        get {
            return target.level
        }
        set {
            // This passes through the new level to the target so that it can filter correctly with the new level
            target.level = newValue
        }
    }
    public let name: String

    let target: FocusContextualLoggerTarget
    
    public init(name: String, level: LoggerLevel, output: AggregatingLoggerOutput) {
        self.name = name
        target = FocusContextualLoggerTarget(output: output)
        target.level = level
        
        DebugReporting.add(self)
    }

    deinit {
        DebugReporting.remove(self)
    }

    public func setLevel(for topic: TopicPath, to level: LoggerLevel?) {
        target.setLevel(for: topic, to: level)
    }

    public func contextualLogger(with context: LogEventContext) -> ContextSpecificLogger {
        return DefaultContextSpecificLogger(owner: self, target: target, context: context)
    }

    public func contextualLogger(with activity: String, topicPath: TopicPath) -> ContextSpecificLogger {
        let context = LogEventContext(session: DefaultLoggerFactory.noSessionName, activity: activity, topicPath: topicPath, arguments: nil, presenter: nil)
        return DefaultContextSpecificLogger(owner: self, target: target, context: context)
    }
    
    public func add(output: LoggerOutput) {
        target.add(output: output)
    }

    public func copyReport(to path: URL, options: Set<DebugReportOptions>) {
        target.output.copyForArchiving(to: path)
    }

    /// Quick setup default logging behaviours, tracking the specified hierarchy of features.
    public static func setup(initialDebugLogLevel: LoggerLevel = .debug, initialProductionLogLevel: LoggerLevel = .info, briefLogging: Bool = true) {
        let outputs: [LoggerOutput] = [
            PrintLoggerImplementation(prefix: "🐞", timeOnly: briefLogging)
        ]

        let prodOutputs: [LoggerOutput] = [
            PrintLoggerImplementation(prefix: nil, timeOnly: briefLogging)
        ]
        
        Logging.setLoggerOutputs(debug: outputs, level: initialDebugLogLevel, production: prodOutputs, level: initialProductionLogLevel)
    }
}


