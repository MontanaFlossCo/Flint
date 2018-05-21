//
//  URLPatternResult.swift
//  FlintCore
//
//  Created by Marc Palmer on 21/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public enum URLPatternResult {
    case noMatch
    case match(params: [String:String])
}

