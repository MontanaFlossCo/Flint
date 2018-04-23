//
//  ContextualLoggerTarget.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 19/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Implementations of this protocol receive the contextual logging requests and must
/// filter and route them to the `LoggerOutput`.
public protocol ContextualLoggerTarget {

    /// Called for every log event, without any filtering. 
    func log(level: LoggerLevel, context: LogEventContext, content: @escaping @autoclosure () -> String)
}
