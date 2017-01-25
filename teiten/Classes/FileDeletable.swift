//
//  FileOperatable.swift
//  Teiten
//
//  Created by nakajijapan on 2016/05/06.
//  Copyright © 2016年 net.nakajijapan. All rights reserved.
//

import Foundation

protocol FileDeletable {}
extension FileDeletable {
    
    func removeFiles(path targetPath:String) {
        
        let fileManager = FileManager.default
        let contents = try! fileManager.contentsOfDirectory(atPath: targetPath)
        
        for content in contents {
            do {
                try fileManager.removeItem(atPath: "\(targetPath)/\(content)")
            } catch let error as NSError {
                print("failed to remove file: \(error.description)");
            }
        }

    }
    
    func removeFilesByDirecotries(paths targetPaths:[String]) {
        
        let fileManager = FileManager.default
       
        targetPaths.enumerated().forEach { (index: Int, element: String) in
            
            let contents = try! fileManager.contentsOfDirectory(atPath: element)
            for content in contents {
                do {
                    try fileManager.removeItem(atPath: "\(element)/\(content)")
                } catch let error as NSError {
                    print("failed to remove file: \(error.description)");
                }
            }
        }
        
    }
    
}
