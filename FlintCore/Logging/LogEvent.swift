//
//  LogEvent.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 27/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A single log event.
///
/// This includes high level context information so that logs can identify more accurately what items relate to.
///
/// In the case of `Feature` based apps, this means you can tell all the log activity that relates to a specific feature
/// just by looking at the logs. Even if it comes from different subsystems.
public class LogEvent: UniquelyIdentifiable {
    /// The date the event occurred
    public let date: Date
    
    /// The date the event occurred
    public let sequenceID: UInt

    /// A generated unique ID.
    public lazy var uniqueID: String = { return "\(date.timeIntervalSince1970)-\(sequenceID)" }()

    /// The level of the event
    public let level: LoggerLevel

    /// The contextual information for the log event
    public let context: LogEventContext
    
    /// The text to log
    public let text: String
    
    /// Initialise the event
    init(date: Date, sequenceID: UInt, level: LoggerLevel, context: LogEventContext, text: String) {
        self.date = date
        self.sequenceID = sequenceID
        self.level = level
        self.context = context
        self.text = text
    }
}
