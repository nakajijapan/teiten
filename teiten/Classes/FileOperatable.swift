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

protocol FileDeletable {}
extension FileDeletable {
    
    func removeFiles(path targetPath:String) {
        
        let fileManager = NSFileManager.defaultManager()
        let contents = try! fileManager.contentsOfDirectoryAtPath(targetPath)
        
        for content in contents {
            do {
                try fileManager.removeItemAtPath("\(targetPath)/\(content)")
            } catch let error as NSError {
                print("failed to remove file: \(error.description)");
            }
        }

    }
    
    func removeFilesByDirecotries(paths targetPaths:[String]) {
        
        let fileManager = NSFileManager.defaultManager()
       
        targetPaths.enumerate().forEach { (index: Int, element: String) in
            
            let contents = try! fileManager.contentsOfDirectoryAtPath(element)
            for content in contents {
                do {
                    try fileManager.removeItemAtPath("\(element)/\(content)")
                } catch let error as NSError {
                    print("failed to remove file: \(error.description)");
                }
            }
        }
        
    }
    
}