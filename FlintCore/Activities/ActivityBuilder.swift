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
#if os(macOS)
    public var image: NSImage?
#else
    public var image: UIImage?
#endif
    public var imageData: Data?
    public var requiredUserInfoKeys: [String] = []
    public var userInfo: [AnyHashable:Any] = [:]
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
        
        let searchAttributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        searchAttributes.contentDescription = subtitle
        if let imageData = imageData {
            searchAttributes.thumbnailData = imageData
        } else if let image = image {
#if !os(macOS)
            searchAttributes.thumbnailData = UIImagePNGRepresentation(image)
#endif
        }

        builtActivity.contentAttributeSet = searchAttributes

        return builtActivity
    }
}
