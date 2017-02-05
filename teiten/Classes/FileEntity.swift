//
//  FileEntity.swift
//  teiten
//
//  Created by nakajijapan on 2/4/15.
//  Copyright (c) 2015 net.nakajijapan. All rights reserved.
//

import Cocoa

class FileEntity: NSObject, NSPasteboardWriting {
    
    var image: NSImage!
    var fileURL: URL!
    
    override init() {
        
    }
    
    func loadImage(image: NSImage, data: Data) {
        
        self.image = image
        
        let dragPathString   = "\(NSTemporaryDirectory())teiten.jpg"
        let schemePathString = "file://\(dragPathString)"
        
        self.fileURL = URL(string: schemePathString)
        
        if FileManager.default.fileExists(atPath: dragPathString) {
            do {
                try FileManager.default.removeItem(at: self.fileURL)
            } catch let error as NSError {
                print("can not remove. \(error.description)")
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let dateString = dateFormatter.string(from: Date())
        let savePathString = "\(kAppHomePath)/images/\(dateString).jpg"
        
        data.write(to: savePathString, options: true)
        data.write(to: dragPathString, options: true)
    }
    
    // MARK: - NSPasteboardWriting
    
    func writableTypesForPasteboard(pasteboard: NSPasteboard) -> [String] {
        print("\(#function) \(#line) \(self.fileURL.writableTypesForPasteboard(pasteboard))")
        return self.fileURL.writableTypesForPasteboard(pasteboard)
    }
    
    func pasteboardPropertyListForType(type: String) -> AnyObject? {
        print("\(#function) \(#line) \(type) : \(self.fileURL.pasteboardPropertyListForType(type))")
        return self.fileURL.pasteboardPropertyListForType(type)
    }
    
    func writinOptionsForType(type: String!, pasteboard: NSPasteboard!) -> NSPasteboardWritingOptions {
        print("\(#function) \(#line) \(type)")
        return self.fileURL.writingOptionsForType(type, pasteboard: pasteboard)
    }
}
