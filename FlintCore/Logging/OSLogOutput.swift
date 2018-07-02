//
//  OSLogOutput.swift
//  FlintCore
//
//  Created by Marc Palmer on 26/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import os.log

/// A LoggerOutput implementation that sends log events to the system's OSLog.
///
/// The app bundle ID plus action session name are used as the subsystem, e.g:
///
/// `co.montanafloss.demo.main`
///
/// ...and the "category" is set to the topic path (AKA feature + action path):
///
/// `AppFeatures/DocumentEditing/#Save`
///
public class OSLogOutput: LoggerOutput {

    private var logs: [TopicPath:OSLog] = [:]
    private let bundleID: String
    private let queue = DispatchQueue(label: "tools.flint.OSLogOutput")
    
    public init() {
        bundleID = Bundle.main.bundleIdentifier ?? "missing.bundle.id"
    }
    
    public func log(event: LogEvent) {
        let log = getLog(for: event)

        var text = "\(event.context.activity) | \(event.text)"
        if let arguments = event.context.arguments {
            text.append(" | State: \(arguments)")
        }
        let type: OSLogType
        switch event.level {
            case .debug:   type = .debug
            case .error:   type = .error
            case .info:    type = .info
            case .warning: type = .`default` // There is no warning level, docs say this is for something that might result in a failure
            case .none:
                flintBug("Should never see an event with level .none")
        }
        os_log("%@", log: log, type: type, text)
    }
    
    public func copyForArchiving(to path: URL) {
    }
    
    private func getLog(for event: LogEvent) -> OSLog {
        return queue.sync {
            if let log = logs[event.context.topicPath] {
                return log
            }
            // We should see if it makes sense to do anything else with the subsystem
            let log = OSLog(subsystem: "\(bundleID).\(event.context.session)", category: event.context.topicPath.description)
            logs[event.context.topicPath] = log
            return log
        }
    }
}
