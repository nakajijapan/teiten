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
    
    override init() {
        
    }
    
    func loadImage(image: NSImage, data: NSData) {
        
        self.image = image
        
        let dragPathString   = "\(NSTemporaryDirectory())teiten.jpg"
        let schemePathString = "file://\(dragPathString)"
        
        self.fileURL = NSURL(string: schemePathString)
        
        if NSFileManager.defaultManager().fileExistsAtPath(dragPathString) {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(self.fileURL)
            } catch let error as NSError {
                print("can not remove. \(error.description)")
            }
        }
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let dateString = dateFormatter.stringFromDate(NSDate())
        let savePathString = "\(kAppHomePath)/images/\(dateString).jpg"
        
        data.writeToFile(savePathString, atomically: true)
        data.writeToFile(dragPathString, atomically: true)
    }
    
    // MARK: - NSPasteboardWriting
    
    func writableTypesForPasteboard(pasteboard: NSPasteboard) -> [String] {
        print("\(__FUNCTION__) \(__LINE__) \(self.fileURL.writableTypesForPasteboard(pasteboard))")
        return self.fileURL.writableTypesForPasteboard(pasteboard)
    }
    
    func pasteboardPropertyListForType(type: String) -> AnyObject? {
        print("\(__FUNCTION__) \(__LINE__) \(type) : \(self.fileURL.pasteboardPropertyListForType(type))")
        return self.fileURL.pasteboardPropertyListForType(type)
    }
    
    func writinOptionsForType(type: String!, pasteboard: NSPasteboard!) -> NSPasteboardWritingOptions {
        print("\(__FUNCTION__) \(__LINE__) \(type)")
        return self.fileURL.writingOptionsForType(type, pasteboard: pasteboard)
    }
}
