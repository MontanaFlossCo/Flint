//
//  MotionPermissionAdapter.swift
//  FlintCore
//
//  Created by Marc Palmer on 31/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(CoreMotion)
import CoreMotion
#endif

typealias CMProxyMotionActivityQueryHandler = ([NSObject]?, Error?) -> Void

@objc protocol ProxyMotionActivityManager {
#if canImport(CoreMotion)
    @available(iOS 11, watchOS 4, *)
    @objc static func authorizationStatus() -> CMAuthorizationStatus
    
    @objc static var isActivityAvailable: Bool { get }
    
    @objc(queryActivityStartingFromDate:toDate:toQueue:withHandler:)
    func queryActivityStarting(from start: Date, to end: Date, to queue: OperationQueue, withHandler handler: @escaping CMProxyMotionActivityQueryHandler)
#endif

}

/// Support: iOS 11+, watchOS 4+, tvOS ⛔️, macOS ⛔️
class MotionPermissionAdapter: SystemPermissionAdapter {
    static let activityManagerName = "CMMotionActivityManager"

    static var isSupported: Bool {
#if canImport(CoreMotion)
        if libraryIsLinkedForClass(activityManagerName) {
            if let tempInstance = try? instantiate(classNamed: activityManagerName) {
                let manager = unsafeBitCast(tempInstance, to: ProxyMotionActivityManager.self)
                return type(of: manager).isActivityAvailable
            }
        }
        return false
#else
        return false
#endif
        }
    
    static func createAdapters(for permission: SystemPermissionConstraint) -> [SystemPermissionAdapter] {
        return [MotionPermissionAdapter(permission: permission)]
    }
    
    let permission: SystemPermissionConstraint
    
    var status: SystemPermissionStatus {
#if canImport(CoreMotion)
        if #available(iOS 11, watchOS 4, *) {
            return authStatusToPermissionStatus(type(of: proxyMotionActivityManager).authorizationStatus())
        } else {
            return .unsupported
        }
#else
        return .unsupported
#endif
        }
    
    let usageDescriptionKey: String = "NSMotionUsageDescription"

#if canImport(CoreMotion)
    private lazy var activityManager: AnyObject = { try! instantiate(classNamed: "CMMotionActivityManager") }()
    lazy var proxyMotionActivityManager: ProxyMotionActivityManager = { return unsafeBitCast(self.activityManager, to: ProxyMotionActivityManager.self) }()
#endif

    init(permission: SystemPermissionConstraint) {
        flintBugPrecondition(permission == .motion, "Cannot use MotionPermissionAdapter with: \(permission)")

        self.permission = permission
    }
    
    func requestAuthorisation(completion: @escaping (SystemPermissionAdapter, SystemPermissionStatus) -> Void) {
        let start = Date().addingTimeInterval(-24*60*60)
        let end = Date()

#if canImport(CoreMotion)
        proxyMotionActivityManager.queryActivityStarting(from: start, to: end, to: .main) { [weak self] (activity: [NSObject]?, error: Error?) in
            if let strongSelf = self {
                completion(strongSelf, strongSelf.status)
            }
        }
#else
        completion(self, .unsupported)
#endif
    }
    
#if canImport(CoreMotion)
    @available(iOS 11, watchOS 4, *)
    func authStatusToPermissionStatus(_ authStatus: CMAuthorizationStatus) -> SystemPermissionStatus {
#if os(tvOS)
        return .unsupported
#else
        switch authStatus {
            case .authorized: return .authorized
            case .denied: return .denied
            case .notDetermined: return .notDetermined
            case .restricted: return .restricted
        }
#endif
    }
#endif
}
