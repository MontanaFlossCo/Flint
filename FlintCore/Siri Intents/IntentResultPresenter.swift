//
//  IntentResultPresenter.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 10/01/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The presenter type required when performing an action as a result of receiving a Siri Intent.
/// This is used in Intent extensions to perform the action and forward the response to Siri.
public protocol IntentResultPresenter {
    func showResult(response: FlintIntentResponse)
}

