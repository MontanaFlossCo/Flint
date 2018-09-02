//
//  LogEventContext+Mocking.swift
//  FlintCore
//
//  Created by Marc Palmer on 26/08/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
@testable import FlintCore

extension LogEventContext {
    static func mockContext() -> LogEventContext {
        return LogEventContext(session: "none", activity: "testing", topicPath: ["Test"], arguments: nil, presenter: nil)
    }
}
