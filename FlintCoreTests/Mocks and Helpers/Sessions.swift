//
//  File.swift
//  FlintCore
//
//  Created by Marc Palmer on 13/05/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import FlintCore

enum Sessions {
    static let backgroundSession = ActionSession.init(named: "background", userInitiatedActions: true)
}
