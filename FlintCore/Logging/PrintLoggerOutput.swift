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
    public let formattingStrategy: LogEventFormattingStrategy

    /// Initialise the print logger with a prefix added to every line output, and an option to show only the time
    /// instead of the full date and time.
    convenience public init(prefix: String? = nil, timeOnly: Bool = false) {
        let format = timeOnly ? "HH:mm:ss.SSS" : "y-MM-dd HH:mm:ss.SSS"
        self.init(prefix: prefix, dateFormat: format)
    }

    /// Initialise the logger with a prefix to add to each line, and a custom date format
    public init(prefix: String? = nil, dateFormat: String) {
        formattingStrategy = VerboseLogEventFormatter(prefix: prefix, dateFormat: dateFormat)
    }
    
    public init(formatter: LogEventFormattingStrategy) {
        self.formattingStrategy = formatter
    }
    
    public func log(event: LogEvent) {
        guard let text = formattingStrategy.format(event) else {
            return
        }
        
        // Ensure we don't corrupt stdout
        DispatchQueue.main.async {
            print(text)
        }
    }

    public func copyForArchiving(to path: URL) {
        // NOP, can't do it
    }
}
