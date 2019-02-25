//
//  DismissInput.swift
//  FlintCore
//
//  Created by Marc Palmer on 24/02/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS)
/// The input type for `DismissUIAction`, which will automatically dismiss a presenter that is a `UIViewController`
/// on UIKit platforms.
public struct DismissUIInput: FlintLoggable {
    public let animated: Bool
    
    private init(animated: Bool) {
        self.animated = animated
    }
    
    /// Create an instance of the dismiss input, with the `animated` flag set accordingly.
    /// - see `DismissingUIAction` for usage example.
    public static func animated(_ animated: Bool) -> DismissUIInput {
        return DismissUIInput(animated: animated)
    }
}
#endif
