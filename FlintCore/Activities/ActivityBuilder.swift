//
//  ActivityBuilder.swift
//  FlintCore
//
//  Created by Marc Palmer on 13/06/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import CoreSpotlight
#if os(macOS)
import CoreServices
#else
import MobileCoreServices
#endif

/// A builder used to set required properties
public class ActivityBuilder<T> {
    public let input: T

    private var activity: NSUserActivity
    
    public var title: String? {
        get {
            return activity.title
        }
        set {
            activity.title = newValue
        }
    }
    
    public var subtitle: String?

    private var _keywords: Set<String>?
    /// Lazily created search attributes
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

#if os(macOS)
    public var thumbnail: NSImage?
#else
    public var thumbnail: UIImage?
#endif
    public var thumbnailData: Data?
    public var thumbnailURL: URL?
    public var requiredUserInfoKeys: [String] = []
    public var userInfo: [AnyHashable:Any] = [:]
    
    private var _searchAttributes: CSSearchableItemAttributeSet?
    
    /// Lazily created search attributes
    public var searchAttributes: CSSearchableItemAttributeSet {
        get {
            if _searchAttributes == nil {
                _searchAttributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
            }
            return _searchAttributes!
        }
    }
    
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
        
        if let subtitle = subtitle {
            searchAttributes.contentDescription = subtitle
        }

        if let keywords = _keywords {
            activity.keywords = keywords
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
        
        return builtActivity
    }
}
