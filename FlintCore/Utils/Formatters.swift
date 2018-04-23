//
//  Formatters.swift
//  FlintUI-iOS
//
//  Created by Marc Palmer on 25/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Standard formatters used by Flint
public class Formatters {
    /// - note: This requires iOS 10, macOS 10.12, watchOS 3, tvOS 10 or higher
    static private let jsonDateFormatter = ISO8601DateFormatter()
    static private var detailedDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return dateFormatter
    }()

    static private var relativeDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }()
    
    public static func jsonDate(from date: Date) -> String {
        return jsonDateFormatter.string(from: date)
    }

    public static func detailedDate(from date: Date) -> String {
        return detailedDateFormatter.string(from: date)
    }

    public static func relativeDate(from date: Date) -> String {
        return relativeDateFormatter.string(from: date)
    }
}
