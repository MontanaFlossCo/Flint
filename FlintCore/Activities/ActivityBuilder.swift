//
//  ActivityBuilder.swift
//  FlintCore
//
//  Created by Marc Palmer on 13/06/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

#if canImport(CoreSpotlight)
import CoreSpotlight
#endif

#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit
#endif

#if os(macOS)
import CoreServices
import Cocoa
#else
import MobileCoreServices
#endif

#if canImport(Intents) && canImport(Network) && (os(iOS) || os(watchOS))
import Intents
#endif


/// A builder used to set required properties on an `NSUserActivity`
public class ActivityBuilder<ActionType> where ActionType: Action {
    /// This provides access to the input value for this activity
    public let input: ActionType.InputType
    public private(set) var metadata: ActivityMetadata?
    
    /// Set this to a title to use in the `NSUserActivity`, shown in
    /// search results and suggestions.
    public var title: String?
    
    /// Set this to a title to use in the `NSUserActivity`, shown in
    /// search results and suggestions.
    public var subtitle: String?

    /// Lazily created search attributes
    private var _keywords: Set<String>?
    /// Set this to optional keywords to use spotlight indexing of this activity by key words
    public var keywords: Set<String> {
        get {
            if _keywords == nil {
                _keywords = Set<String>()
            }
            return _keywords!
        }
        set {
            _keywords = newValue
        }
    }

#if canImport(CoreSpotlight)
#if canImport(Cocoa)
    /// Set to a thumbnail to show when displaying this activity
    public var thumbnail: NSImage?
#elseif canImport(UIKit)
    /// Set to a thumbnail to show when displaying this activity
    public var thumbnail: UIImage?
#endif
    /// Set to thumbnail data to show when displaying this activity
    public var thumbnailData: Data?
    /// Set to URL pointing at local thumbnail data to show when displaying this activity
    public var thumbnailURL: URL?
#endif

    /// Set this to the userInfo keys required to continue the activity later.
    /// - note: You must specify this if you want Siri prediction to work and you have arguments.
    /// This is so Siri can learn which variations of the activity your users are performing, e.g. which
    /// document they are opening.
    /// - note: If you are using Flint's automatic URLs you can use this to store extra values,
    /// but any data not included in the URL will not be placed into the Input when continuing your action.
    public var requiredUserInfoKeys: Set<String> = []
    
    /// Set this to the keys and values that the action needs to reconstruct its Input when
    /// continuing later.
    public var userInfo: [AnyHashable:Any] = [:]
    
    /// !!! TODO: Add a wrapper for these so actions on watchOS and tvOS don't have to adapt to the platform,
    /// as currently this `searchAttributes` property will not exist and cause compile errors on actions that
    /// try to call use this when building activities.
    /// Note we can't use just `canImport(CoreSpotlight)` as this exists on tvOS and watchOS but the attribute set does not
#if canImport(CoreSpotlight)
#if os(iOS) || os(macOS)
    private var _searchAttributes: CSSearchableItemAttributeSet?

    /// Lazily created search attributes. Amend these to provide extra search proeprties.
    public var searchAttributes: CSSearchableItemAttributeSet {
        get {
            if _searchAttributes == nil {
                _searchAttributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
            }
            return _searchAttributes!
        }
    }
#endif
#endif

    /// Use Network + Platforms to detect support for Siri Shortcuts
#if canImport(Intents) && canImport(Network) && (os(iOS) || os(watchOS))
    /// Set to the suggested phrase for creating a Siri shortcut to perform this activity
    @available(iOS 12, watchOS 5, *)
    public var suggestedInvocationPhrase: String? {
        get {
            return _suggestedInvocationPhrase
        }
        set {
            _suggestedInvocationPhrase = newValue
        }
    }
    private var _suggestedInvocationPhrase: String?
#endif

    /// Set to an app-unique identifier to allow this activity to be deleted
    /// at a later point, to prevent further Siri suggestions.
    @available(iOS 12, watchOS 5, *)
    public var persistentIdentifier: String? {
        get {
            return _persistentIdentifier
        }
        set {
            _persistentIdentifier = newValue
        }
    }
    private var _persistentIdentifier: String?

    /// Set to override the default activity type set by Flint
    public var activityType: String?
    private var activityTypeGenerator: () -> String
    
    private var cancelled: Bool = false
    private let appLink: URL?
    private var canAutoContinueActivity: Bool = true
    
    init(activityTypeGenerator: @escaping () -> String, input: ActionType.InputType, appLink: URL?) {
        self.input = input
        self.activityTypeGenerator = activityTypeGenerator
        self.appLink = appLink
    }
    
    /// Call to cancel the activity and not have anything published
    public func cancel() {
        cancelled = true
    }
    
    /// Call to indicate that your activity configuration created with the builder will not require Flint's ability
    /// to auto-continue activities received from the system.
    ///
    /// If your action's feature has a URL mapping for the action, or the action's input type conforms to `ActivitytCodable`,
    /// your application delegate can just all `Flint.continueActivity` to automatically dispatch incoming activities.
    ///
    /// If neither of those is the case, you must use your own logic in your app delegate to establish what action
    /// needs to be performed. If this is want you want, you must call this function to stop Flint applying footgun
    /// defences that will terminate your app with a warning.
    public func bypassFlintContinueActivity() {
        canAutoContinueActivity = false
    }
    
    /// Called internally to execute a builder function on an action to create an NSUserActivity for a given input
    func build(_ block: (_ builder: ActivityBuilder<ActionType>) throws -> Void) throws -> NSUserActivity? {
        canAutoContinueActivity = true
        
        // Check for inputs that describe themselves by conforming to MetadataRepresentable
        if let metadataInput = input as? ActivityMetadataRepresentable {
            let metadata = metadataInput.metadata 
            self.metadata = metadata
            title = metadata.title
            subtitle = metadata.subtitle
            if let keywords = metadata.keywords {
                self.keywords = keywords
            }

#if canImport(CoreSpotlight)
#if os(iOS) || os(macOS)
            thumbnail = metadata.thumbnail
            thumbnailURL = metadata.thumbnailURL
            thumbnailData = metadata.thumbnailData

            if let searchAttributes = metadata.searchAttributes {
                _searchAttributes = searchAttributes
            }
#endif
#endif
        }
    
        canAutoContinueActivity = false
        // Check for inputs that can be coded to and from userInfo by conforming to ActivityCodable
        if let codableInput = input as? ActivityCodable {
            if let activityUserInfo = codableInput.encodeForActivity() {
                userInfo = activityUserInfo
            }
            requiredUserInfoKeys = codableInput.requiredUserInfoKeys
            canAutoContinueActivity = true
        } else if let url = appLink {
            // Put in the auto link, if set and part of a URLMapped feature
            userInfo = [ActivitiesFeature.autoURLUserInfoKey: url]
            requiredUserInfoKeys = [ActivitiesFeature.autoURLUserInfoKey]
            canAutoContinueActivity = true
        }
    
        try block(self)
        
        flintAdvisoryPrecondition(canAutoContinueActivity, "Flint will not be able to perform the action for this activity. Activity has no URL mapping and the action input is not ActivityCodable. Add a URL mapping or make the input conform to ActivityCodable, or call bypassFlintContinueActivity() if you have custom handling of the incoming activity.")
        
        guard !cancelled else {
            return nil
        }

        let activity = NSUserActivity(activityType: activityType ?? activityTypeGenerator())

        activity.isEligibleForSearch = ActionType.activityEligibility.contains(.search)
        activity.isEligibleForHandoff = ActionType.activityEligibility.contains(.handoff)
        activity.isEligibleForPublicIndexing = ActionType.activityEligibility.contains(.publicIndexing)

        // This is the only compile-time check we have available to us right now for Xcode 10 SDKs, that doesn't
        // require raising the language level to Swift 4.2 in the target.
#if canImport(Intents) && canImport(Network) && (os(iOS) || os(watchOS))
        if #available(iOS 12, watchOS 5, *) {
            activity.isEligibleForPrediction = ActionType.activityEligibility.contains(.prediction)
            // Force search eligibility as this is required for prediction too
            if activity.isEligibleForPrediction {
                activity.isEligibleForSearch = true
            }

            activity.suggestedInvocationPhrase = suggestedInvocationPhrase ?? ActionType.suggestedInvocationPhrase
        }

        if #available(iOS 12, watchOS 5, *) {
            activity.persistentIdentifier = persistentIdentifier
        }
#endif

        activity.title = title
        activity.addUserInfoEntries(from: userInfo)
        activity.requiredUserInfoKeys = requiredUserInfoKeys

#if canImport(CoreSpotlight)
#if os(iOS) || os(macOS)
        if let subtitle = subtitle {
            searchAttributes.contentDescription = subtitle
        }

        if let imageURL = thumbnailURL {
            searchAttributes.thumbnailURL = imageURL
        } else if let imageData = thumbnailData {
            searchAttributes.thumbnailData = imageData
        } else if let image = thumbnail {
#if !os(macOS)
#if swift(>=4.2)
            searchAttributes.thumbnailData = image.pngData()
#else
            searchAttributes.thumbnailData = UIImagePNGRepresentation(image)
#endif
#endif
        }

        // Don't assign search attributes if they were never needed, so use the non-self-populating property
        activity.contentAttributeSet = _searchAttributes
#endif
#endif

        if let keywords = _keywords {
            activity.keywords = keywords
        }

        /// !!! TODO: Add #if DEBUG or similar around these, once we establish how we are doing that.
        applySanityChecks(to: activity)

        return activity
    }
    
    // Apply sanity checks to a generated activity
    func applySanityChecks(to activity: NSUserActivity) {
        // Check 1: Check there is a title
        if activity.isEligibleForSearch || activity.isEligibleForHandoff  {
            flintUsagePrecondition(activity.title != nil, "Activity cannot be indexed for search without a title set")
        }

        // Check 2: If there are required userInfo keys, make sure there's a value for every key
        if let foundRequiredKeys = activity.requiredUserInfoKeys, let userInfo = activity.userInfo {
            let infoKeys = Set(userInfo.keys)
            let missingKeys = foundRequiredKeys.filter { !infoKeys.contains($0) }
            flintUsagePrecondition(missingKeys.count == 0, "Action for activity type '\(activity.activityType)' supplies userInfo in prepareActivity() but does not define all the keys required by requiredUserInfoKeys, missing values for: \(missingKeys)")
        }

#if canImport(Intents) && canImport(Network) && (os(iOS) || os(watchOS))
        if #available(iOS 12, watchOS 5, *) {
            if activity.isEligibleForPrediction && activity.suggestedInvocationPhrase == nil {
                flintAdvisoryNotice("Registering an activity eligible for prediction with \(ActionType.self) but suggestedInvocationPhrase is nil")
            }
        }
#endif
    }
}
