//
//  DefaultContextualLogger.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 16/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A trivial `ContextualLogger` implementation that retains the context but defers to a `ContextualLoggerTarget` for the actual
/// filtering and log output.
public class DefaultContextSpecificLogger: ContextSpecificLogger {
    public var level: LoggerLevel { return owner.level }
    public var ownerName: String { return owner.name }
    public let context: LogEventContext
    private let target: ContextualLoggerTarget
    private let owner: ContextualLoggerFactory

    init(owner: ContextualLoggerFactory, target: ContextualLoggerTarget, context: LogEventContext) {
        self.owner = owner
        self.target = target
        self.context = context
    }

    public func info(_ content: @escaping @autoclosure () -> String) {
        target.log(level: .info, context: context, content: content)
    }
    
    public func error(_ content: @escaping @autoclosure () -> String) {
        target.log(level: .error, context: context, content: content)
    }
    
    public func warning(_ content: @escaping @autoclosure () -> String) {
        target.log(level: .warning, context: context, content: content)
    }
    
    public func debug(_ content: @escaping @autoclosure () -> String) {
        target.log(level: .debug, context: context, content: content)
    }
}
