//
//  LoggerOutput.swift
//  FlintCore
//
//  Created by Marc Palmer on 31/12/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// An implementation of logging output. This is the protocol to implement to output logs to your chosen logging system.
///
/// - note: Log events for excluded levels will never be passed in to the implementation. Interactions with your logging system's
/// own log level may need close attention. The expectation at the app level is that if something passes the log filtering
/// of Flint that it will appear in the logs. This is particularly important for Focus where Flint will flip the
/// effective log level to DEBUG to allow all loggic for the focused topics through. If your logging subsystem is set
/// to log level INFO then these log events will not be logged.
public protocol LoggerOutput {

    /// Called to log a single log event. Implementations must output this to the logging system in an appropriate format.
    /// The intention is that *every* event passed to this function must be included in the log. Flint has already
    /// applied log level filtering.
    func log(event: LogEvent)
    
    /// Implement this function to copy the logs produced to files under the `path` URL.
    /// This is used by `Flint.gatherReportZip()` to obtain a debug report containing all information relating to the
    /// user's situation.
    func copyForArchiving(to path: URL)
}
