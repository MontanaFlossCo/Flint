//
//  DefaultAuthorisationController.swift
//  FlintCore
//
//  Created by Marc Palmer on 09/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

class DefaultAuthorisationController: AuthorisationController {
    public var permissions: Set<SystemPermission> = []
    var sortedPermissionsToAuthorize: [SystemPermission] = []
    var permissionsNotAuthorized: [SystemPermission] = []
    let coordinator: PermissionAuthorisationCoordinator
    var cancelled: Bool = false
    
    init(coordinator: PermissionAuthorisationCoordinator, permissions: Set<SystemPermission>) {
        self.coordinator = coordinator
        self.permissions = permissions
    }

    public func begin() {
        precondition(!cancelled, "Cannot use a cancelled authorisation controller")
        coordinator.willBeginPermissionAuthorisation(for: permissions) { permissionsToRequest in
            if let orderedPermissions = permissionsToRequest, permissions.count > 0 {
                sortedPermissionsToAuthorize = orderedPermissions
                next()
            }
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
            coordinator.willRequestPermission(for: permission) { action in
                switch action {
                    case .requestPermission:
                        Flint.permissionChecker.requestAuthorization(for: permission) { [weak self] permission, status in
                            guard let strongSelf = self else {
                                return
                            }
                            if status == .notDetermined {
                                strongSelf.permissionsNotAuthorized.append(permission)
                            }
                            strongSelf.coordinator.didRequestPermission(for: permission, status: status)
                        }
                    case .skipPermission:
                        permissionsNotAuthorized.append(permission)
                        next()
                    case .cancelAll:
                        permissionsNotAuthorized.append(contentsOf: sortedPermissionsToAuthorize)
                        sortedPermissionsToAuthorize.removeAll()
                        cancel()
                }
            }
        }
        
        complete(cancelled: false)
    }

    func complete(cancelled: Bool) {
        coordinator.didCompletePermissionAuthiorisation(cancelled: cancelled, outstandingPermissions: permissionsNotAuthorized)
    }
}
