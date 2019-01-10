//
//  IntentMapping.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 10/01/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public typealias IntentActionExecutor = (_ input: FlintIntent, _ presenter: IntentResultPresenter, _ completion: Action.Completion) -> Action.Completion.Status

/// A single intent mapping using internally for debug metadata and mapping incoming INIntent instances to a closure
/// that can perform the Action that was mapped to that intent type by a URLMapped feature.
///
/// - see: `Flint.performIntent`
struct IntentMapping {
    let intentType: FlintIntent.Type
    let actionTypeName: String
    let executorProxy: (_ intent: FlintIntent, _ presenter: IntentResultPresenter, _ completion: Action.Completion) -> Action.Completion.Status
    
    init(intentType: FlintIntent.Type, actionTypeName: String, executor: @escaping IntentActionExecutor) {
        self.intentType = intentType
        self.actionTypeName = actionTypeName
        executorProxy = { (input: FlintIntent, presenter: IntentResultPresenter, completion: Action.Completion) -> Action.Completion.Status in
            executor(input, presenter, completion)
        }
    }

    func performAction(for intent: FlintIntent, presenter: IntentResultPresenter, completion: Action.Completion) -> Action.Completion.Status {
        return executorProxy(intent, presenter, completion)
    }
}

