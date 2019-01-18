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
public protocol UntypedIntentResponsePresenter {
    func showResult(response: FlintIntentResponse)
}

/// The default
public class IntentResponsePresenter<ResponseType>: UntypedIntentResponsePresenter where ResponseType: FlintIntentResponse {
    let completion: (ResponseType) -> Void
    
    public init(completion: @escaping (ResponseType) -> Void) {
        self.completion = completion
    }
    
    public func showResult(response: FlintIntentResponse) {
        guard let safeResponse = response as? ResponseType else {
            fatalError("Wrong response type, expected \(ResponseType.self) but got \(type(of: response))")
        }
        completion(safeResponse)
    }
}


