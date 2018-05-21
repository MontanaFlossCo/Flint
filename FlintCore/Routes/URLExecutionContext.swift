//
//  URLExecutionContext.swift
//  FlintCore
//
//  Created by Marc Palmer on 21/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A wrapper that provides all the details of a successful url mapping lookup.
///
/// This is used to execution an action bound to a URL mapping, supplying the extra parameters
/// parsed out of the URL itself.
///
/// - see: `URLPattern
public struct URLExecutionContext {
    /// The closure that can perform the action with the supplied parameters and presentation router.
    /// This closure is used because actions have associated types and Self requirements, so the actual
    /// action is captured when the URL mapping is declared and the type is known, so we only need to
    /// call this closure and not worry about the viral generic requirements or type erasure challenges.
    let executor: URLExecutor
    
    /// The parameters parsed out from the URL mapping itself, if any
    let parsedParameters: [String:String]?
    
    /// The pattern that matched the incoming URL that resulted in this execution context.
    /// This can be passed to the acttion to allow it to vary behaviour based on the URL mapping that matched.
    let matchedPattern: URLPattern
}
