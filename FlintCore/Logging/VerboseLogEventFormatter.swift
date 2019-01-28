//
//  VerboseLogEventFormatter.swift
//  FlintCore
//
//  Created by Marc Palmer on 24/01/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The default verbose formatter for log events.
///
/// Includes an optional prefix for each line, and the time in HH:mm:ss.SSS format.
///
public class VerboseLogEventFormatter: LogEventFormattingStrategy {
    public let dateFormatter: DateFormatter?
    public let prefix: String

    /// Initialise the logger with a prefix to add to each line, and a custom date format
    public init(prefix: String? = nil, dateFormat: String? = "HH:mm:ss.SSS") {
        self.prefix = prefix ?? ""
        if let dateFormat = dateFormat {
            let dateFormatter = DateFormatter()
            let format = DateFormatter.dateFormat(fromTemplate: dateFormat, options: 0, locale: nil)
            dateFormatter.dateFormat = format
            self.dateFormatter = dateFormatter
        } else {
            dateFormatter = nil
        }
    }
    
    public func format(_ event: LogEvent) -> String? {
        let level = event.level.description

        let date: String = dateFormatter != nil ? dateFormatter!.string(from: event.date) : ""

        let args: String
        if let arguments = event.context.arguments {
            args = " | State: \(arguments)"
        } else {
            args = ""
        }
        let text = "\(prefix)\(date) \(level) • \(event.context.session) | Activity '\(event.context.activity)' | \(event.context.topicPath) | \(event.text)\(args)"
        return text
    }
}
