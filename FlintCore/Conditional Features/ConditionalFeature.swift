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
    func begin(for permissions: Set<SystemPermission>, completion: (_ permissionsToRequest: [SystemPermission]?) -> ())
    func beforePermissionRequest(for permission: SystemPermission, completion: (_ action: SystemPermissionRequestAction) -> ())
    func afterPermissionRequest(for permission: SystemPermission, status: SystemPermissionStatus)
    func complete(for controller: AuthorisationController, cancelled: Bool)
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
    public static func requestMissingPermissions(using coordinator: PermissionAuthorisationCoordinator,
                                                 completion: (_ permission: SystemPermission, _ status: SystemPermissionStatus) -> Void) -> AuthorisationController {
        let authorisationController = DefaultAuthorisationController(coordinator: coordinator)

        let constraints = Flint.constraintsEvaluator.evaluate(for: self)
        guard constraints.unsatisfied.permissions.count > 0 else {
            return authorisationController
        }
        
        let permissions = constraints.unsatisfied.permissions
        
        coordinator.begin(for: permissions) { permissionsToRequest in
            if let orderedPermissions = permissionsToRequest, permissions.count > 0 {
                authorisationController.begin(with: orderedPermissions)
            }
        }
        return authorisationController
    }
    
    /// Function for binding a conditional feature and action pair, to restrict how this can be done externally by app code.
    public static func action<A>(_ action: A.Type) -> ConditionalActionBinding<Self, A> where A: Action {
        return ConditionalActionBinding(feature: self, action: action)
    }

}

public protocol AuthorisationController {
    var permissions: [SystemPermission] { get }
    
    func cancel()
}

class DefaultAuthorisationController: AuthorisationController {
    public var permissions: [SystemPermission] = []
    var remainingPermissions: [SystemPermission] = []
    let coordinator: PermissionAuthorisationCoordinator
    
    init(coordinator: PermissionAuthorisationCoordinator) {
        self.coordinator = coordinator
    }
    
    func begin(with permissions: [SystemPermission]) {
        self.permissions = permissions
        remainingPermissions = permissions
        
        next()
    }
    
    func next() {
        if let permission = remainingPermissions.first {
            coordinator.beforePermissionRequest(for: permission) { action in
                switch action {
                    case .requestPermission:
                        Flint.permissionChecker.requestAuthorization(for: permission) { [weak self] permission, status in
                            self?.coordinator.afterPermissionRequest(for: permission, status: status)
                        }
                    case .skipPermission:
                        next()
                    case .cancelAll:
                        remainingPermissions.removeAll()
                        cancel()
                }
            }
        } else {
            coordinator.complete(for: self, cancelled: false)
        }
    }

    public func cancel() {
        coordinator.complete(for: self, cancelled: true)
    }
}
