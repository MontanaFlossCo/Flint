//
//  URLMappings.swift
//  FlintCore
//
//  Created by Marc Palmer on 29/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A simple representation of the supported `URLMapping`(s) for actions.
/// This is produced by the `URLMappingsBuilder`, and used to collect all the mappings for the app.
public class URLMappings {
    private (set) var mappings = [(String, URLMapping)]()

    init() {
    
    }
    
    func add(_ mapping: URLMapping, actionType: Any.Type) {
        mappings.append((String(reflecting: actionType), mapping))
    }
}
