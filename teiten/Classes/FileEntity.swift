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
    var fileURL:URL!
    
    override init() {
        
    }
    
    func loadImage(_ image: NSImage, data: Data) {
        
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
        
        try? data.write(to: URL(fileURLWithPath: savePathString), options: [.atomic])
        try? data.write(to: URL(fileURLWithPath: dragPathString), options: [.atomic])
    }
    
    // MARK: - NSPasteboardWriting
    
    func writableTypes(for pasteboard: NSPasteboard) -> [String] {
        print("\(#function) \(#line) \(self.fileURL.writableTypes(for: pasteboard))")
        return self.fileURL.writableTypes(for: pasteboard)
    }
    
    func pasteboardPropertyList(forType type: String) -> Any? {
        print("\(#function) \(#line) \(type) : \(self.fileURL.pasteboardPropertyList(forType: type))")
        return self.fileURL.pasteboardPropertyList(forType: type)
    }
    
    func writinOptionsForType(_ type: String!, pasteboard: NSPasteboard!) -> NSPasteboardWritingOptions {
        print("\(#function) \(#line) \(type)")
        return self.fileURL.writingOptions(forType: type, pasteboard: pasteboard)
    }
}
