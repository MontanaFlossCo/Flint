//
//  SpeechRecognitionPermissionAdapt.swift
//  FlintCore
//
//  Created by Marc Palmer on 03/06/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(Speech)
import Speech
#endif

#if canImport(Speech)
@objc protocol ProxySpeechRecognizer {
    // These are not static as we call them on the class
    @objc func authorizationStatus() -> SFSpeechRecognizerAuthorizationStatus

    @objc(requestAuthorization:)
    func requestAuthorization(_ handler: @escaping (SFSpeechRecognizerAuthorizationStatus) -> Void)
}
#endif

/// Support: iOS 10+, macOS ⛔️, watchOS ⛔️, tvOS ⛔️
class SpeechRecognitionPermissionAdapter: SystemPermissionAdapter {
    static var isSupported: Bool {
#if canImport(Speech)
        if #available(iOS 10, *) {
            let isLinked = libraryIsLinkedForClass("SFSpeechRecognizer")
            return isLinked
        } else {
            return false
        }
#else
        return false
#endif
        }
    
    static func createAdapters(for permission: SystemPermissionConstraint) -> [SystemPermissionAdapter] {
        return [SpeechRecognitionPermissionAdapter(permission: permission)]
    }
    
    let permission: SystemPermissionConstraint
    
#if canImport(Speech)
    lazy var speechRecognizerClass: AnyObject = { NSClassFromString("SFSpeechRecognizer")! }()
    lazy var proxySpeechRecognizerClass: ProxySpeechRecognizer = { unsafeBitCast(self.speechRecognizerClass, to: ProxySpeechRecognizer.self) }()
#endif

    var status: SystemPermissionStatus {
#if canImport(Speech)
        if #available(iOS 10, *) {
            return authStatusToPermissionStatus(proxySpeechRecognizerClass.authorizationStatus())
        } else {
            return .unsupported
        }
#else
        return .unsupported
#endif
        }
    
    let usageDescriptionKey: String = "NSSpeechRecognitionUsageDescription"

    init(permission: SystemPermissionConstraint) {
        flintBugPrecondition(permission == .speechRecognition, "Cannot use SpeechRecognitionPermissionAdapter with: \(permission)")
        self.permission = permission
    }
    
    func requestAuthorisation(completion: @escaping (SystemPermissionAdapter, SystemPermissionStatus) -> Void) {
#if canImport(Speech)
        proxySpeechRecognizerClass.requestAuthorization() { [weak self] status in
            if let strongSelf = self {
                completion(strongSelf, strongSelf.status)
            }
        }
#else
        completion(self, .unsupported)
#endif
    }
    
#if canImport(Speech)
    @available(iOS 10, *)
    func authStatusToPermissionStatus(_ authStatus: SFSpeechRecognizerAuthorizationStatus) -> SystemPermissionStatus {
        switch authStatus {
            case .authorized: return .authorized
            case .denied: return .denied
            case .notDetermined: return .notDetermined
            case .restricted: return .restricted
        }
    }
#endif
}

