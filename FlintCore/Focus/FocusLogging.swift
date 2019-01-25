//
//  FocusLogging.swift
//  FlintCore
//
//  Created by Marc Palmer on 06/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// This is a logger output implementation that captures log events in a buffer of limited length, for use in reporting
/// and UI.
///
/// This will log whatever is coming out of the logging subsystem, so if Focus is enabled, it will capture only items
/// that are in the focus area.
///
/// - see: `FocusLogDataAccessFeature` which provides realtime access to the data within this logging buffer.
public class FocusLogging: LoggerOutput {
    public private(set) var history: LIFOArrayQueueDataSource<LogEvent>
    
    public init(maxCount: Int) {
        history = LIFOArrayQueueDataSource<LogEvent>(maxCount: maxCount)
    }
    
    public func log(event: LogEvent) {
        history.append(event)
    }

    public func copyForArchiving(to path: URL) {
    }
}
