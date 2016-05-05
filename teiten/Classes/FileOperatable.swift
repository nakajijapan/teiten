//
//  FileOperatable.swift
//  Teiten
//
//  Created by nakajijapan on 2016/05/06.
//  Copyright © 2016年 net.nakajijapan. All rights reserved.
//

import Foundation

protocol FileOperatable {
    var baseDirectoryPath:String { get set }
}

protocol FileDeletable: FileOperatable {
}

extension FileDeletable {
    
    func removeFiles() {
        
        let fileManager = NSFileManager.defaultManager()
        let contents = try! fileManager.contentsOfDirectoryAtPath(self.baseDirectoryPath)
        
        for content in contents {
            do {
                try fileManager.removeItemAtPath("\(self.baseDirectoryPath)/\(content)")
            } catch let error as NSError {
                print("failed to remove file: \(error.description)");
            }
        }
    }
    
}