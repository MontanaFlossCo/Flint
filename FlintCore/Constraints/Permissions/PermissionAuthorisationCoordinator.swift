//
//  PermissionAuthorisationController.swift
//  FlintCore
//
//  Created by Marc Palmer on 09/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The interface to the coordinator that apps must implement if they want to hook
/// in to the permission authorisation controller flow.
///
/// Apps can use this interface to present custom UI before the authorisation flow starts,
/// and update this before and after each permission is requested, with control over what happens next.
///
/// For example you may have non-modal UI that shows the user what the camera will be used for,
/// and it contains a SKIP button. If they tap this, you call the completion handler passing `.skip` and the
/// controller will move on to the next permission, or finish the flow if there are no more permissions required.
///
/// - see `ConditionalFeature.permissionAuthorisationController(using:)` and `AuthorisationController`
public protocol PermissionAuthorisationCoordinator {

    /// Called once when the authorisation controller flow begins.
    /// You can prepare the UI to tell the user that soon they will be asked for system permissions.
    /// You must indicate the desired sort order of the permission requests by supplying an ordered Array of permissions.
    ///
    /// - param permissions: The set of all permissions that the flow will attempt to request.
    /// - param completion: The closure you must call to continue the authorisation flow, passing in the sorted array of
    /// permissions to actually request from the user. If you have non-modal UI shown by this function, you would only
    /// call `completion` when the user indicates they are ready to start
    func willBeginPermissionAuthorisation(for permissions: Set<SystemPermissionConstraint>, completion: (_ permissionsToRequest: [SystemPermissionConstraint]) -> ())
    
    /// Called before each individual permission is about to be requested. Your coordinator implementation
    /// can show custom UI and if desired veto individual permissions, for example with a "Not now" and "OK" button in the
    /// UI, your implementation of this function would call `completion(.skip)` if the user chose "Not now" and `completion(.request)`
    /// if they press "OK". If there is a cancel or "X" close button, you would call `completion(.cancelAll)` to terminate
    /// the flow immediately.
    ///
    /// - param permission: The permission that will be requested from the user when you call `completion(.request)`
    /// - param completion: The closure you must call to move the flow forward by either skipping, requesting or cancelling.
    func willRequestPermission(for permission: SystemPermissionConstraint, completion: (_ action: SystemPermissionRequestAction) -> ())
    
    /// Called after the user has been prompted for the permission, passing the status that results from that.
    /// This is your chance to update your onboarding UI to indicate the outcome of what the user has done.
    /// If they denied the permission you may want to explain what that means for them, or how they can fix this later.
    ///
    /// You must call `completion` to continue the flow to the next permission or end of the flow, in case you have
    /// some UI that you need to show the user, such as "You've denied camera access! When you want to enable this later
    /// go to the Settings app".
    ///
    /// - param permission: The permission that the user just authorised
    /// - param status: The permission's authorisation status after the authorisation. This will usually be `.denied` or `.authorised`
    /// - param completion: You must call this closure to continue the flow. If you want the flow to cancel immediately, pass `true`
    func didRequestPermission(for permission: SystemPermissionConstraint, status: SystemPermissionStatus, completion: (_ shouldCancel: Bool) -> ())
    
    /// Called when the entire flow has finished. Clean up any onboardig UI and perhaps show the user
    /// information about how to resolve any issues if there are still permissions outstanding.
    ///
    /// - param cancelled: This is `true` if the flow was terminated as a result of `willRequestPermission` passing `.cancelAll` to the completion handler,
    /// or your code making a call to `cancel()` on the `AuthorisationController`.
    /// - param outstandingPermissions: The list of any permissions that are still not authorised, that this feature requires.
    func didCompletePermissionAuthorisation(cancelled: Bool, outstandingPermissions: [SystemPermissionConstraint]?)
}
