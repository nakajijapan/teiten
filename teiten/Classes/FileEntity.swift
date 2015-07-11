//
//  FileEntity.swift
//  teiten
//
//  Created by nakajijapan on 2/4/15.
//  Copyright (c) 2015 net.nakajijapan. All rights reserved.
//

import Cocoa

class FileEntity: NSObject, NSPasteboardWriting {
    
    var image:NSImage!
    var fileURL:NSURL!
    
    func loadImage(image: NSImage, data: NSData) {
        
        self.image = image
        
        let dragPath   = "\(NSTemporaryDirectory())teiten.jpg"
        let schemePath = "file://\(dragPath)"
        
        self.fileURL = NSURL(string: schemePath)
        
        if NSFileManager.defaultManager().fileExistsAtPath(dragPath) {
            NSFileManager.defaultManager().removeItemAtURL(self.fileURL, error: nil)
        }
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let date = NSDate()
        let stringDate = dateFormatter.stringFromDate(date)
        let savePath = "\(kAppHomePath)/images/\(stringDate).jpg"
        
        data.writeToFile(savePath, atomically: true)
        data.writeToFile(dragPath, atomically: true)
    }
    
    // MARK: - NSPasteboardWriting

    func writableTypesForPasteboard(pasteboard: NSPasteboard!) -> [AnyObject]! {
        return self.fileURL.writableTypesForPasteboard(pasteboard)
    }
    
    func pasteboardPropertyListForType(type: String!) -> AnyObject! {
        return self.fileURL.pasteboardPropertyListForType(type)
    }
    
    func writinOptionsForType(type: String!, pasteboard: NSPasteboard!) -> NSPasteboardWritingOptions {
        return self.fileURL.writingOptionsForType(type, pasteboard: pasteboard)
    }
}
