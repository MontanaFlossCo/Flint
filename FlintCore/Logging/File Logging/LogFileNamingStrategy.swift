//
//  LogFileNamingStrategy.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 24/01/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The abstraction for creating new log file names
public protocol LogFileNamingStrategy {
    func next() -> String
}

