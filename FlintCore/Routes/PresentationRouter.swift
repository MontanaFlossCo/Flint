//
//  UserInterfaceRouter.swift
//  FlintCore
//
//  Created by Marc Palmer on 29/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Indicates the result of a presentation request.
public enum PresentationResult<PresenterType> {
    
    /// Return this if routing is not supported for the given action. Any action could be passed, and most
    /// UIs will only support routing a subset of them.
    case unsupported
    
    /// Return this if the user performed something that would prevent the action continuing, such as an active
    /// edited document with unsaved changes
    case userCancelled
    
    /// Return this to indicate the app cannot create the presenter right now, perhaps Log In is required or similar
    case appCancelled
    
    /// Return this to indicate the app has already prepared the UI for this, but the action should not be performed.
    /// e.g. it represents the existing state of the UI already and performing the action again would do nothing
    case appPerformed
    
    /// Return this when the app has prepared the UI for presenting the action and include the presenter the action should use.
    case appReady(presenter: PresenterType)
}

/// Applications must implement this protocol to provide UI for actions that
/// are invoked for URLs or deep linking.
///
/// The implementation is responsible for providing an instance of the right kind of presenter for a given action.
///
/// How this works is up to your UI platform and your application. On UIKit for example you may choose to
/// return `.appCancelled` if the user has a modal view controller presented currently, or unsaved data in an
/// incomplete workflow. For the case where the current UI state can present the UI for the specified action,
/// the view controllers required must be created in the correct configuration and the final presenter instance returned
/// with a value of `.appReady`
public protocol PresentationRouter {
    /// Called to obtain the presenter, if possible, for the static action binding provided.
    /// - return: The outcome of the presentation routing.
    /// - see: `PresentationResult<PresenterType>`
    func presentation<FeatureType, ActionType>(for actionBinding: StaticActionBinding<FeatureType, ActionType>, input: ActionType.InputType) -> PresentationResult<ActionType.PresenterType>
    
    /// Called to obtain the presenter, if possible, for the conditional action binding provided.
    /// - return: The outcome of the presentation routing.
    /// - see: `PresentationResult<PresenterType>`
    func presentation<FeatureType, ActionType>(for conditionalActionBinding: ConditionalActionBinding<FeatureType, ActionType>, input: ActionType.InputType) -> PresentationResult<ActionType.PresenterType>
}
