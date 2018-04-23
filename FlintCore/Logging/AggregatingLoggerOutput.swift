//
//  AggregatingLoggerOutput
//  FlintCore
//
//  Created by Marc Palmer on 31/12/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// An implementation of `LoggerOutput` that aggregates multiple `LoggerOutput`.
/// Use this if you need your logging to go to multiple destinations.
///
/// Must only be called from a single queue/thread.
public class AggregatingLoggerOutput: LoggerOutput {
    public private (set) var loggerOutputs: [LoggerOutput]
    
    /// Initialise the aggregating output with a list of outputs to which all the events are sent.
    public init(outputs: [LoggerOutput]) {
        self.loggerOutputs = outputs
    }

    public func log(event: LogEvent) {
        /// This could be parallelized on a bg queue couldn't it?
        for impl in loggerOutputs {
            impl.log(event: event)
        }
    }

    public func copyForArchiving(to path: URL) {
        for output in loggerOutputs {
            output.copyForArchiving(to: path)
        }
    }

    /// Used internally to add focus logging output which captures a fixed length in-memory buffer of events
    func add(output: LoggerOutput) {
        loggerOutputs.append(output)
    }

}
