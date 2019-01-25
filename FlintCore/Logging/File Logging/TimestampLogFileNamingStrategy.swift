//
//  TimestampLogFileNamingStrategy.swift
//  FlintCore
//
//  Created by Marc Palmer on 24/01/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Log file naming strategy that uses a prefix and current date
public class TimestampLogFileNamingStrategy: LogFileNamingStrategy {
    let timestampFormatter: ISO8601DateFormatter
    let namePrefix: String
    
    public init(namePrefix: String) {
        self.namePrefix = namePrefix
        timestampFormatter = ISO8601DateFormatter()
        timestampFormatter.formatOptions = .withFullDate
    }
    
    public func next() -> String {
        let date = timestampFormatter.string(from: Date())
        return "\(namePrefix)-\(date).log"
    }
}
