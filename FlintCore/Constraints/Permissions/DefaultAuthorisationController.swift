//
//  DefaultAuthorisationController.swift
//  FlintCore
//
//  Created by Marc Palmer on 09/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The default implementation of `AuthorisationController` that will iterate over the unsatisfied permissions
/// of a feature and ask the permission checker to authorise each one in turn.
///
/// This controller works together with a coordinator you supply, which can orchestrate your UI in such a way that
/// your users feel informed about what is happening, giving you the chance to maximise the likelihood they will
/// authorise all the permissions so they can use your feature.
///
/// - see: `ConditionalFeature.permissionAuthorisationController` for how you get an instance of this in your app.
class DefaultAuthorisationController: AuthorisationController {
    public var permissions: Set<SystemPermissionConstraint> = []
    var sortedPermissionsToAuthorize: [SystemPermissionConstraint] = []
    var permissionsNotAuthorized: [SystemPermissionConstraint] = []
    let coordinator: PermissionAuthorisationCoordinator?
    var cancelled: Bool = false
    var retryHandler: (() -> Void)?
    
    init(coordinator: PermissionAuthorisationCoordinator?, permissions: Set<SystemPermissionConstraint>) {
        self.coordinator = coordinator
        self.permissions = permissions
    }

    public func begin(retryHandler: (() -> Void)?) {
        precondition(!cancelled, "Cannot use a cancelled authorisation controller")
        self.retryHandler = retryHandler
        if let coordinator = coordinator {
            coordinator.willBeginPermissionAuthorisation(for: permissions) { permissionsToRequest in
                if permissions.count > 0 {
                    sortedPermissionsToAuthorize = permissionsToRequest
                    next()
                }
            }
        } else {
            sortedPermissionsToAuthorize = Array(permissions)
            next()
        }
    }
    
    public func cancel() {
        precondition(!self.cancelled, "Cannot restart a cancelled authorisation controller")
        complete(cancelled: true)
        cancelled = true
    }

    func next() {
        precondition(!cancelled, "Cannot use a cancelled authorisation controller")
        
        if sortedPermissionsToAuthorize.count > 0 {
            let permission = sortedPermissionsToAuthorize.removeFirst()
            
            func _requestPermission() {
                Flint.permissionChecker.requestAuthorization(for: permission) { [weak self] permission, status in
                    guard let strongSelf = self else {
                        return
                    }
                    if status != .authorized {
                        strongSelf.permissionsNotAuthorized.append(permission)
                    }
                    if let coordinator = strongSelf.coordinator {
                        coordinator.didRequestPermission(for: permission, status: status, completion: { shouldCancel in
                            if !shouldCancel {
                                strongSelf.next()
                            } else {
                                strongSelf.cancel()
                            }
                        })
                    } else {
                        // Assume if there is no coordinator that we'll just carry on to the next
                        strongSelf.next()
                    }
                }
            }

            if let coordinator = coordinator {
                coordinator.willRequestPermission(for: permission) { action in
                    switch action {
                        case .request:
                            _requestPermission()
                        case .skip:
                            permissionsNotAuthorized.append(permission)
                            next()
                        case .cancelAll:
                            permissionsNotAuthorized.append(contentsOf: sortedPermissionsToAuthorize)
                            sortedPermissionsToAuthorize.removeAll()
                            cancel()
                    }
                }
            } else {
                _requestPermission()
            }
        } else {
            complete(cancelled: false)
        }
    }

    func complete(cancelled: Bool) {
        if permissionsNotAuthorized.count > 0 && !cancelled {
            FlintInternal.logger?.warning("Authorisation controller completed with outstanding permissions required: \(self.permissionsNotAuthorized)")
        }
        coordinator?.didCompletePermissionAuthorisation(cancelled: cancelled, outstandingPermissions: permissionsNotAuthorized)
        if !cancelled {
            if let retryHandler = self.retryHandler {
                DispatchQueue.main.async {
                    retryHandler()
                }
            }
        }
    }
}
