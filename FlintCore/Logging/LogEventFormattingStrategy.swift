//
//  LogEventFormattingStrategy.swift
//  FlintCore
//
//  Created by Marc Palmer on 24/01/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The abstraction for formatting a `LogEvent` as a string for output
public protocol LogEventFormattingStrategy {
    func format(_ event: LogEvent) -> String?
}
