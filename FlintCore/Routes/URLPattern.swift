//
//  URLPattern.swift
//  FlintCore
//
//  Created by Marc Palmer on 21/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public protocol URLPattern {
    var urlPattern: String { get }
    var isValidForLinkCreation: Bool { get }
    func match(path: String) -> URLPatternResult
    func buildPath(with parameters: [String:String]?) -> String?
}
