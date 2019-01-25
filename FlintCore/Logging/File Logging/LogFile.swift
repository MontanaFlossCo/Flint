//
//  LogFile.swift
//  FlintCore
//
//  Created by Marc Palmer on 24/01/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Write access to a single log file
class LogFile {
    let filename: URL
    private let handle: FileHandle
    
    init(filename: URL, createNew: Bool) throws {
        self.filename = filename
        
        if createNew {

            try Data().write(to: filename, options: .atomicWrite)
#if os(iOS) || os(watchOS)
            let attributes = [
                 FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
            ]
            try FileManager.default.setAttributes(attributes, ofItemAtPath: filename.path)
#endif
        }

        guard let handle = FileHandle(forWritingAtPath: filename.path) else {
            flintBug("No file at expected path: \(filename)")
        }
        self.handle = handle
        handle.seekToEndOfFile()

    }

    deinit {
        handle.closeFile()
    }
    
    func write(_ text: String) {
        handle.seekToEndOfFile()

        guard let data = text.data(using: .utf8) else {
            flintBug("Could not create Data from text")
        }
        handle.write(data)
    }
}
