//
//  FlintImage.swift
//  FlintCore
//
//  Created by Marc Palmer on 14/06/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if os(macOS)
import Cocoa
#elseif os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

#if os(macOS)
public typealias FlintImage = NSImage
#elseif os(iOS) || os(tvOS)
public typealias FlintImage = UIImage
#elseif os(watchOS)
public typealias FlintImage = WKInterfaceImage
#endif

