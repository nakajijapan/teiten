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
    
    func loadImage(image: NSImage, data: Data) {
        
        self.image = image
        
        let dragPathString   = "\(NSTemporaryDirectory())teiten.jpg"
        let dragSchemePathString = "file://\(dragPathString)"
        
        self.fileURL = URL(string: dragSchemePathString)
        
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
        let saveSchemePathString = "file://\(kAppHomePath)/images/\(dateString).jpg"
        
        do {
            try data.write(to: URL(string: saveSchemePathString)!, options: .atomicWrite)
        } catch {
            print("file write error: \(saveSchemePathString) >> \(error)")
        }

        do {
            try data.write(to: URL(string: dragSchemePathString)!, options: .atomicWrite)
        } catch {
            print("file write error: \(dragSchemePathString) >> \(error)")
        }
        
    }
    
    // MARK: - NSPasteboardWriting
    
    func writableTypes(for pasteboard: NSPasteboard) -> [String] {
        let fileURL = self.fileURL as NSURL
        print("\(#function) \(#line) \(fileURL.writableTypes(for: pasteboard)))")
        return fileURL.writableTypes(for: pasteboard)
    }
    
    func pasteboardPropertyList(forType type: String) -> Any? {
        guard self.fileURL != nil else {
            return nil
        }
        
        let fileURL = self.fileURL as NSURL
        print("\(#function) \(#line) \(type) : \(fileURL.pasteboardPropertyList(forType: type))")
        return fileURL.pasteboardPropertyList(forType: type)
    }
    
    func writingOptions(forType type: String, pasteboard: NSPasteboard) -> NSPasteboardWritingOptions {
        guard self.fileURL != nil else {
            return .promised
        }

        let fileURL = self.fileURL as NSURL
        print("\(#function) \(#line) \(type)")
        return fileURL.writingOptions(forType: type, pasteboard: pasteboard)
    }
    
    
}
