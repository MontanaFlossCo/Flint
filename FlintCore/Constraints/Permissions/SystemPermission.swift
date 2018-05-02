//
//  SystemPermission.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public enum SystemPermission: Permission {
    case camera
    case photos
    case location(usage: LocationUsage)

// The rest of these are "coming soon"
/*
    case contacts
    case calendars
    case reminders
    case homeKit
    case health
    case motionAndFitness
    case speechRecognition
    case bluetoothSharing
    case mediaLibrary
*/

}

