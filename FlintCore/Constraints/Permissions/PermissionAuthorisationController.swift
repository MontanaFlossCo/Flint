//
//  PermissionAuthorisationController.swift
//  FlintCore
//
//  Created by Marc Palmer on 09/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public protocol PermissionAuthorisationCoordinator {
    func willBeginPermissionAuthorisation(for permissions: Set<SystemPermission>, completion: (_ permissionsToRequest: [SystemPermission]?) -> ())
    func willRequestPermission(for permission: SystemPermission, completion: (_ action: SystemPermissionRequestAction) -> ())
    func didRequestPermission(for permission: SystemPermission, status: SystemPermissionStatus)
    func didCompletePermissionAuthiorisation(cancelled: Bool, outstandingPermissions: [SystemPermission]?)
}
