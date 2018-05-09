//
//  AuthorisationController.swift
//  FlintCore
//
//  Created by Marc Palmer on 09/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// An authorisation controller is used to request a set of system permissions.
///
/// Using `ConditionalFeature.permissionAuthorisationController(using:)` you can get an instance of
/// a controller in your app for any conditional feature you have. You then call `begin` to
/// start the flow.
///
/// The flow can be multi-step if your feature has multiple permissions that are not yet authorised, and the
/// coordinator object you pass to `ConditionalFeature.permissionAuthorisationController` gives you the opportunity
/// to update your UI at each step, giving the user the ability to skip or cancel the process.
///
/// - see: `ConditionalFeature.permissionAuthorisationController`
public protocol AuthorisationController {

    /// Call this to begin the authorisation flow. If the user tried to perform an action of the feature
    /// and you wish to automatically execute the action again at the end of the flow, if all the permissions are
    /// authorised, then supply a closure that will attempt the action again.
    ///
    /// - param retryHandler: An optional closure that will be called at the end of the authorisation flow only
    /// if all the required permissions are now authorised.
    func begin(retryHandler: (() -> Void)?)
    
    /// Call this function to terminate the authorisation flow, perhaps in response to a `Cancel` button,
    /// or a request to dismiss your view controller.
    func cancel()
}
