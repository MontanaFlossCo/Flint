//
//  PurchasePreconditionEvaluator.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The precondition evaluator for purchases requirements.
public class PurchasePreconditionEvaluator: FeaturePreconditionEvaluator {
    let purchaseTracker: PurchaseTracker
    
    public init(purchaseTracker: PurchaseTracker) {
        self.purchaseTracker = purchaseTracker
    }
    
    public func isFulfilled(_ precondition: FeaturePrecondition, for feature: ConditionalFeatureDefinition.Type) -> Bool? {
        guard case let .purchase(requirement) = precondition else {
            fatalError("Incorrect precondition type '\(precondition)' passed to purchase evaluator")
        }

        return requirement.isFulfilled(validator: purchaseTracker)
    }
}


