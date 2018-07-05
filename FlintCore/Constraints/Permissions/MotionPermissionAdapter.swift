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
    static func authorizationStatus() -> CMAuthorizationStatus
    static func isActivityAvailable() -> Bool
    func queryActivityStarting(from start: Date, to end: Date, to queue: OperationQueue, withHandler handler: @escaping CMProxyMotionActivityQueryHandler)
}

/// Support: iOS 11+, macOS ⛔️, watchOS 4+, tvOS ⛔️
class MotionPermissionAdapter: SystemPermissionAdapter {
    static let activityManagerName = "CMMotionActivityManager"

    static var isSupported: Bool {
#if canImport(CoreMotion)
        if libraryIsLinkedForClass(activityManagerName) {
            if let tempInstance = try? instantiate(classNamed: activityManagerName) {
                let manager = unsafeBitCast(tempInstance, to: ProxyMotionActivityManager.self)
                return type(of: manager).isActivityAvailable()
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
//    typealias AuthorizationStatusFunc = () -> Int
//    typealias QueryActivityFunc = (_ from: Date, _ to: Date, _ to: OperationQueue, _ withHandler: CMMotionActivityQueryHandler) -> Void

//    let getAuthorizationStatus: AuthorizationStatusFunc!
//    lazy var queryActivityStarting: QueryActivityFunc! = {
//        return {
//            let binding = try! DynamicInvocation(object: activityManager, methodName: "queryActivityStarting")
//            typealias FuncType = @convention(c) (NSDate, NSDate, OperationQueue, CMMotionActivityQueryHandler) -> Void
//            binding.perform { (generator: () -> FuncType, instance: AnyObject, selector: Selector) -> Void in
//                let function = generator()
//                function(instance, selector,
//            }
//        }
//    }()
    private lazy var activityManager: AnyObject = { try! instantiate(classNamed: "CMMotionActivityManager") }()
    lazy var proxyMotionActivityManager: ProxyMotionActivityManager = { return unsafeBitCast(self.activityManager, to: ProxyMotionActivityManager.self) }()
#endif

    init(permission: SystemPermissionConstraint) {
        flintBugPrecondition(permission == .motion, "Cannot use MotionPermissionAdapter with: \(permission)")

//#if canImport(CoreMotion)
//        getAuthorizationStatus = try! dynamicBindIntReturn(toStaticMethod: "authorizationStatus", on: "CMMotionActivityManager")
//#endif
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
