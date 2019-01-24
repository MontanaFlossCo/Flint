//
//  Logging.swift
//  FlintCore
//
//  Created by Marc Palmer on 09/10/2017.
//  Copyright © 2017 Montana Floss Co. All rights reserved.
//

import Foundation

/// This type provides access to the App's loggers.
///
/// Logging in Flint is slightly different and solves several problems:
///
/// 1. Excessively noisy logs in non-development builds (a separate logger for debug logging, always silenced in production)
/// 2. The inability to tell what actual user activity a log entry relates to (see: topic paths, contextual logging)
/// 3. The typical reliance on a specific logging framework. Wire up whatever implementation you like here.
/// 4. Focusing on logs only related to specific application features, e.g. drill down into just your "Share" feature's logging
///
/// Abstracting logging is one of the more laughable and tedious things in computing, after all how many ways do we
/// need to log text? However nothing out there supports contextual logging and topic paths which are crucial for Flint.
/// So here we are.
///
/// Flint's logging is somewhat decoupled from the rest of Flint and works like this:
///
/// 1. Something in the App calls `Logging.development?.contextualLogger(...)` or `Logging.production.contextualLogger(...)` to get
/// a logger that has information about what the user is doing.
/// 2. The resulting `ContextSpecificLogger`, if not nil is passed to subsystems that require logging. This is the biggest
/// difference with other logging systems that assume the logger never changes.
/// 3. The subsystems call one of the logging functions on the logger.
/// 4. The `ContextualLogger` delegates the actual logging to a `ContextualLoggerTarget`, which can filter events or log levels
/// as desired
/// 5. The `DefaultContextualLoggerTarget` filters events according to Focus rules, and sends output to a `LoggerOutput` instance
/// which is the final output of the log text.
///
/// The chain of execution is along these lines:
///
/// `ContextualLogger` -> `ContextualLoggerTarget` -> `LoggerOutput`
///
/// The `LoggerOutput` is the only think you need to implement for your logging framework, e.g. a layer that uses CocoaLumberjack or Apple's log systems,
/// or Fabric's `CLS_LOG` rolling log buffer.
///
/// Production logging is always available, so that logger factory is not optional. Debug logging can be entirely disabled
/// for production builds, resulting is close to zero overheads due to the optional dereferencing.
///
/// This solves the problem of polluting production logs with excessive internal debug info, without having to dial down
/// log levels in production.
///
/// The implementation of `ContextualLoggerTarget` can peform filtering of events by topic path or other properties of the
/// `context` (see `DefaultLogger`) and those `ContextSpecificLogger` implementations then pass the logging info on to the
/// `LoggerOutput` implementation which writes to whatever output you desire.
///
/// There is an `AggregatingLoggerOutput` provided so you can compose multiple log outputs easily and drive them from
/// the same contextual loggers, e.g. to output to Console as well as an ASL log file.
///
/// - see: `DefaultLoggerFactory.setup()` for the simple console logging used by default when using `Flint.quickSetup`.
public struct Logging {
    // Code is not executed if logger is not set up, avoids all overhead in production as logger is nil
    public static var development: ContextualLoggerFactory?
    
    /// Code using this logger always causes some overhead, as there must be a production logger set.
    /// Loggers should always test the log level first before evaluation the log text, so that @autoclosure can be
    /// used to avoid evaluation of the input data if the log level is not appropriate.
    public static var production: ContextualLoggerFactory!
}

extension Logging {
    /// Called internally to set up the outputs for the factories
    public static func setLoggerOutputs(debug debugOutputs: [LoggerOutput]?, level debugLevel: LoggerLevel, production productionOutputs: [LoggerOutput]?, level productionLevel: LoggerLevel) {
        if let debugOutputs = debugOutputs {
            development = DefaultLoggerFactory(name: "development", level: debugLevel, output: AggregatingLoggerOutput(outputs: debugOutputs))
        }
        if let productionOutputs = productionOutputs {
            production = DefaultLoggerFactory(name: "production", level: productionLevel, output: AggregatingLoggerOutput(outputs: productionOutputs))
        }
    }
}

