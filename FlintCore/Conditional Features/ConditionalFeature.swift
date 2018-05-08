//
//  ConditionalFeature.swift
//  FlintCore
//
//  Created by Marc Palmer on 21/12/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Features that are not guaranteed to be available all the time must conform to this protocol.
///
/// You implement a conditional feature like so:
///
/// ```
/// public class TimelineFeature: ConditionalFeature {
///     /// Set the availability to .purchasRequired, .runtimeEvaluated or .userToggled as appropriate
///     public static var availability: FeatureAvailability = .runtimeEvaluated
///
///     public static var description: String = "Maintains an in-memory timeline of actions for debugging and reporting"
///
///     /// If availability is `runtimeEvaluated`, you must make `isAvailable` return whether or not it is available.
///     /// Otherwise do not define a property for it and the `DefaultAvailabilityChecker` will be used to work out
///     /// the correct value of this by calling into the `UserDefaultsFeatureToggles` or `PurchaseValidator`.
///     public static var isAvailable: Bool? = true
///
///     /// If using `runtimeEvaluated` you can use this function to set `isAvailable` at startup based on
///     /// some other condition. Beware of dependency on other features and non-determinate initialising sequence.
///     public static func prepare(actions: FeatureActionsBuilder) {
///         if isAvailable == true {
///             // Tracks the user's history of actions performed
///             Flint.dispatcher.add(observer: TimelineDispatchObserver.instance)
///         }
///     }
/// }
/// ```
///
/// Apps must call `request` to test if the action is available, and then call `perform` with the resulting request instance.
public protocol ConditionalFeature: ConditionalFeatureDefinition {

    /// Call to request invocation of the conditionally available action.
    /// - return: nil if the action's feature is not available, or a request instance that can be used to `perform`
    /// the action directly or on a specific `ActionSession` if the feature is available
    static func request<T>(_ actionBinding: ConditionalActionBinding<Self, T>) -> ConditionalActionRequest<Self, T>?
}

public enum SystemPermissionRequestAction {
    case requestPermission
    case skipPermission
    case cancelAll
}

public protocol PermissionAuthorisationCoordinator {
    func willBeginPermissionAuthorisation(for permissions: Set<SystemPermission>, completion: (_ permissionsToRequest: [SystemPermission]?) -> ())
    func willRequestPermission(for permission: SystemPermission, completion: (_ action: SystemPermissionRequestAction) -> ())
    func didRequestPermission(for permission: SystemPermission, status: SystemPermissionStatus)
    func didCompletePermissionAuthiorisation(cancelled: Bool, outstandingPermissions: [SystemPermission]?)
}

public extension ConditionalFeature {
    
    /// Verifies that the feature is correctly prepared in Flint and tests `isAvailable` to see if it is true.
    /// If so, returns a request that can be used to perform the action, otherwise `nil`.
    ///
    /// The default `isAvailable` implementation will delegate to the `AvailabilityChecker` to see if the feature is available.
    public static func request<T>(_ actionBinding: ConditionalActionBinding<Self, T>) -> ConditionalActionRequest<Self, T>? {
        Flint.requiresSetup()
        Flint.requiresPrepared(feature: actionBinding.feature)

        /// The action is possible only if this feature is currently available
        guard let available = isAvailable, available == true else {
            return nil
        }
        return ConditionalActionRequest(actionBinding: actionBinding)
    }

    /// Request permissions for all unauthorised permission requirements, using the supplied presenter
    public static func permissionAuthorisationController(using coordinator: PermissionAuthorisationCoordinator) -> AuthorisationController? {
        let constraints = Flint.constraintsEvaluator.evaluate(for: self)
        guard constraints.unsatisfied.permissions.count > 0 else {
            return nil
        }
        
        return DefaultAuthorisationController(coordinator: coordinator, permissions: constraints.unsatisfied.permissions)
    }
    
    /// Function for binding a conditional feature and action pair, to restrict how this can be done externally by app code.
    public static func action<A>(_ action: A.Type) -> ConditionalActionBinding<Self, A> where A: Action {
        return ConditionalActionBinding(feature: self, action: action)
    }

}

public protocol AuthorisationController {
    func begin()
    func cancel()
}

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
        } else {
            complete(cancelled: false)
        }
    }

    func complete(cancelled: Bool) {
        coordinator.didCompletePermissionAuthiorisation(cancelled: cancelled, outstandingPermissions: permissionsNotAuthorized)
    }
}
