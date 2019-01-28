//
//  URLMappings.swift
//  FlintCore
//
//  Created by Marc Palmer on 29/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A simple representation of the supported `URLMapping`(s) for actions.
///
/// This is produced by the `URLMappingsBuilder`, and used to collect all the mappings for a single feature, with
/// a sort of type-erasure for the action type, which is required for action metadata binding elsewhere, so we can
/// show developers the URLs mapped to a given action type
public class URLMappings {
    typealias URLPatternActionNamePair = (String, String)
    
    private (set) var mappings = [(URLPatternActionNamePair, URLMapping)]()

    init() {
    
    }
    
    func add<ActionType>(_ mapping: URLMapping, actionType: ActionType.Type) {
        let key = (mapping.pattern.urlPattern, String(reflecting: actionType))
        mappings.append((key, mapping))
    }
}
