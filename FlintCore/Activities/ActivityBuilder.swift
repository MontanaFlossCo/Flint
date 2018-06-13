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
#if canImport(UIKit)
import UIKit
#endif
#if os(macOS)
import CoreServices
import Cocoa
#else
import MobileCoreServices
#endif

/// A builder used to set required properties
public class ActivityBuilder<T> {
    /// This provides access to the input value for this activity
    public let input: T

    private var activity: NSUserActivity
    
    /// Set this to a title to use in the `NSUserActivity`, shown in
    /// search results and suggestions.
    public var title: String? {
        get {
            return activity.title
        }
        set {
            activity.title = newValue
        }
    }
    
    /// Set this to a title to use in the `NSUserActivity`, shown in
    /// search results and suggestions.
    public var subtitle: String?

    /// Lazily created search attributes
    private var _keywords: Set<String>?
    /// Set this to optional keywords to use spotlight indexing of this activity
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
    public var requiredUserInfoKeys: [String] = []
    
    /// Set this to the keys and values that the action needs to reconstruct its Input when
    /// continuing later.
    public var userInfo: [AnyHashable:Any] = [:]
    
/// !!! TODO: Add a wrapper for these so actions on watchOS and tvOS don't have to adapt to the platform
// Note we can't use canImport(CoreSpotlight) as this exists on tvOS and watchOS but the attribute set does not
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

    private var cancelled: Bool = false
    
    init(baseActivity: NSUserActivity, input: T) {
        activity = baseActivity
        self.input = input
    }
    
    /// Call to cancel the activity and not have anything published
    public func cancel() {
        cancelled = true
    }
    
    /// Called internally to execute a builder function on an action to create an NSUserActivity for a given input
    func build(_ block: (_ builder: ActivityBuilder<T>) -> Void) -> NSUserActivity? {
        block(self)
        
        guard !cancelled else {
            return nil
        }
        
        let builtActivity = activity

        builtActivity.addUserInfoEntries(from: userInfo)
        
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
            searchAttributes.thumbnailData = UIImagePNGRepresentation(image)
#endif
        }

        // Don't assign search attributes if they were never needed, so use the non-self-populating property
        builtActivity.contentAttributeSet = _searchAttributes
#endif
#endif

        if let keywords = _keywords {
            activity.keywords = keywords
        }


        return builtActivity
    }
}
