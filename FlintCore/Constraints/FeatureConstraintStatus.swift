//
//  FeatureConstraintStatus.swift
//  FlintCore
//
//  Created by Marc Palmer on 29/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// This type represents the current status of a single constraint on a feature, after evaluation
/// by the `FeatureConstraintsEvaluator`.
///
/// - see: `FeatureConstraintsEvaluator` and `FeatureConstraintsEvaluation`
public enum FeatureConstraintStatus: Hashable {
    /// The constraint is not currectly active, e.g. it does not apply to the current runtime platform
    case notActive
    
    /// Indicates that the constraint is active, but it is not yet known whether it is satisfied or not, pending
    /// further (usually asynchronous) checks.
    case notDetermined
    
    /// Indicates that the constraint has not been satisfied, and hence the feature cannot be used
    case notSatisfied

    /// Indicates that the constraint is satisfied, and the feature can be used if all other constraints are
    /// also satisfied.
    case satisfied
}
