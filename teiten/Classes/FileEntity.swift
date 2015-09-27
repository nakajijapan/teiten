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
        
        let dragPath   = "\(NSTemporaryDirectory())teiten.jpg"
        let schemePath = "file://\(dragPath)"
        
        //println("\(__FUNCTION__) : \(__LINE__) path = \(path)")
        //println("\(__FUNCTION__) : \(__LINE__) schemePath = \(schemePath)")
        
        self.fileURL = NSURL(string: schemePath)
        
        if NSFileManager.defaultManager().fileExistsAtPath(dragPath) {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(self.fileURL)
            } catch _ {
            }
        }
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let date = NSDate()
        let stringDate = dateFormatter.stringFromDate(date)
        let savePath = "\(kAppHomePath)/images/\(stringDate).jpg"
        
        //println("\(__FUNCTION__) \(__LINE__) \(stringDate)")
        //println("\(__FUNCTION__) \(__LINE__) \(path)")
        
        data.writeToFile(savePath, atomically: true)
        data.writeToFile(dragPath, atomically: true)
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
