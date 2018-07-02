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

/// Support: iOS 10+, macOS ⛔️, watchOS ⛔️, tvOS ⛔️
class SpeechRecognitionPermissionAdapter: SystemPermissionAdapter {
    static var isSupported: Bool {
#if canImport(Speech)
        if #available(iOS 10, *) {
            return true
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
    
    var status: SystemPermissionStatus {
#if canImport(Speech)
        if #available(iOS 10, *) {
            return authStatusToPermissionStatus(SFSpeechRecognizer.authorizationStatus())
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
        SFSpeechRecognizer.requestAuthorization() { [weak self] status in
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

