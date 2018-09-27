//
//  SiriIntentsFeature.swift
//  FlintCore
//
//  Created by Marc Palmer on 24/09/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(Intents)
import Intents
#endif

@objc
protocol FlintSiriIntent {
// Returns the identifier of the receiver.
    // Could be used to keep track of the entire transaction for resolve, confirm and handleIntent
    var identifier: String? { get }

    // A human-understandable string representation of the intent's user-facing behavior
    @available(iOS 11.0, *)
    var intentDescription: String? { get }

    // A human-understandable string that can be shown to the user as an suggestion of the phrase they might want to use when adding intent as a shortcut to Siri.
    @available(iOS 12.0, *)
    var suggestedInvocationPhrase: String? { get set }

    // Set an image associated with a parameter on the receiver. This image will be used in display of the receiver throughout the system.
    @objc(setImage:forParameterNamed:)
    @available(iOS 12.0, *)
    func setImage(_ image: INImage?, forParameterNamed parameterName: String)

    @objc(imageForParameterNamed:)
    @available(iOS 12.0, *)
    func image(forParameterNamed parameterName: String) -> INImage?
    
    func keyImage() -> INImage?
}

extension INIntent: FlintSiriIntent { }

struct FlintSiriIntentWrapper: FlintLoggable {
    let intent: FlintSiriIntent
}

/// The is the internal Flint feature for automatic Siri Intent donation and handling.
public final class SiriIntentsFeature: ConditionalFeature, FeatureGroup {
    public static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.runtimeEnabled()
    }
    
    public static var subfeatures: [FeatureDefinition.Type] = [
        IntentShortcutDonationFeature.self
    ]

    /// Set this to `false` to disable automatic user activity publishing
#if os(iOS) || os(watchOS) || os(macOS)
    public static var isEnabled: Bool? = true
#else
    public static var isEnabled: Bool? = false
#endif

    public static var description: String = "Siri Intent handling and continuation"

    static var handleIntent = action(HandleIntentAction.self)
    
    public static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(handleIntent)
    }
}

/// This action is used by `Flint.continueActivity` to perform an action associated with a SiriKit Intent.
///
/// These can come to the application from Siri interactions or `NSUserActivity` that we previously registered with the
/// system with an `intent` value. In the case of Siri, an Intent extension can pass the system an `NSUserActivity` that
/// includes an `INIntent` the user can perform by tapping on the Siri intent reponse panel, or by indicating that
/// the intent requested of the extension must be performed in-app instead.
final class HandleIntentAction: UIAction {
    static let description = "Receive a wrapped INIntent and perform the action associated with it"
    
    typealias InputType = FlintSiriIntentWrapper
    typealias PresenterType = PresentationRouter
    
    static func perform(context: ActionContext<FlintSiriIntentWrapper>, presenter: PresentationRouter, completion: Completion) -> Completion.Status {
        // 1. Pull out the intent
        
        // 2. Map it to an action executor

        // 3. Call it
        
        return completion.completedSync(.success)
    }
}
