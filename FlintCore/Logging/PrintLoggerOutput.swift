//
//  PrintLoggerImplementation.swift
//  FlintCore
//
//  Created by Marc Palmer on 31/12/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A trivial logger that uses Swift `print` to stdout. This is not very useful except
/// for debugging without a dependency on another logging framework, as used in Flint demo projects.
public class PrintLoggerImplementation: LoggerOutput {
    let prefix: String?
    let dateFormatter = DateFormatter()
    
    /// Initialise the print logger with a prefix added to every line output, and an option to show only the time
    /// instead of the full date and time.
    convenience public init(prefix: String? = nil, timeOnly: Bool = false) {
        let format = timeOnly ? "HH:mm:ss.SSS" : "y-MM-dd HH:mm:ss.SSS"
        self.init(prefix: prefix, dateFormat: format)
    }

    /// Initialise the logger with a prefix to add to each line, and a custom date format
    public init(prefix: String? = nil, dateFormat: String) {
        let format = DateFormatter.dateFormat(fromTemplate: dateFormat, options: 0, locale: nil)
        dateFormatter.dateFormat = format
        self.prefix = prefix
    }
    
    public func log(event: LogEvent) {
        let date = dateFormatter.string(from: event.date)
        
        let level = event.level.description
        let text = "\(date) \(level) • \(event.context.session) | Activity '\(event.context.activity)' | \(event.context.topicPath) | \(event.text) | State: \(event.context.arguments ?? "nil")"
        
        // Ensure we don't corrupt stdout
        DispatchQueue.main.async {
            if let prefix = self.prefix {
                print(prefix, text)
            } else {
                print(text)
            }
        }
    }

    public func copyForArchiving(to path: URL) {
        // NOP, can't do it
    }
}
