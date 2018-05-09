//
//  AuthorisationController.swift
//  FlintCore
//
//  Created by Marc Palmer on 09/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public protocol AuthorisationController {
    func begin(retryHandler: (() -> Void)?)
    
    func cancel()
}
