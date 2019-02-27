//
//  IntentTypes.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 10/01/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(Intents)
import Intents
#endif

///
/// Types to avoid compile dependency on Intents framework when it is not available
//
#if canImport(Intents)
public typealias FlintIntentResponse = INIntentResponse
#else
public class FakeIntentResponse {
}
public typealias FlintIntentResponse = FakeIntentResponse
#endif

/// The input type for handling intents.
///
/// This is used to avoid having to expose hard dependencies on `INIntent` in our public facing APIs for
/// platforms or apps that do not import Intents.
struct FlintIntentWrapper: FlintLoggable {
#if canImport(Intents)
    let intent: INIntent
#endif
}

#if canImport(Intents) && (os(iOS) || os(watchOS) || os(macOS))
public typealias FlintIntent = INIntent
#else
public class FalseIntent {
}
public typealias FlintIntent = FalseIntent
#endif

extension FlintIntent: FlintLoggable {
}

public typealias LoggableIntent = FlintIntent & FlintLoggable

