//
//  MovieMakerWithMovies.swift
//  Teiten
//
//  Created by nakajijapan on 2015/10/01.
//  Copyright © 2015年 net.nakajijapan. All rights reserved.
//

import Cocoa
import AVFoundation
import CoreMedia
import CoreVideo
import CoreGraphics
import Foundation
import NKJMovieComposer

protocol MovieMakerWithMoviesDelegate {
    func movieMakerDidAddObject(current: Int, total: Int)
}

class MovieMakerWithMovies: NSObject {
    
    var delegate:MovieMakerWithMoviesDelegate?
    var size:NSSize!
    
    // MARK: - File Util
    
    func getMovies() -> [String] {
        
        // get home directory path
        let homeDir = "\(kAppHomePath)/videos"
        let fileManager = NSFileManager.defaultManager()
        let paths:Array = try! fileManager.contentsOfDirectoryAtPath(homeDir)
        var files:[String] = []
        
        for path in paths {
            
            if path.hasSuffix("DS_Store") {
                continue
            }
            
            files.append("\(homeDir)/\(path)")
        }
        
        return files
    }
    
    func deleteFiles() {
        
        // get home directory path
        let homeDir = "\(kAppHomePath)/videos"
        let fileManager = NSFileManager.defaultManager()
        let list:Array = try! fileManager.contentsOfDirectoryAtPath(homeDir)
        
        for path in list {
            
            do {
                try fileManager.removeItemAtPath("\(homeDir)/\(path)")
            } catch let error as NSError {
                print("failed to remove file: \(error.description)");
            }
            
        }
    }
    
    //MARK: - movie
    
    func composeMovies(composedMoviePath:String, success: (() -> Void)) {
        
        // delete file if file already exists
        let fileManager = NSFileManager.defaultManager();
        if fileManager.fileExistsAtPath(composedMoviePath) {
            
            do {
                try fileManager.removeItemAtPath(composedMoviePath)
            } catch let error as NSError {
                print("failed to make directory: \(error.description)");
            }
            
        }

        //fileManager.createFileAtPath(composedMoviePath, contents: nil, attributes: nil)
        
        var current = 1
        
        let movieComposition = NKJMovieComposer()
        movieComposition.videoComposition.renderSize = CGSize(width: self.size.width, height: self.size.height)

        let moviePaths = self.getMovies()
        for moviePath in moviePaths {

            // movie
            let movieURL = NSURL(fileURLWithPath: moviePath)
            let layerInstruction = movieComposition.addVideo(movieURL)
            
            self.delegate?.movieMakerDidAddObject(current, total: moviePaths.count)
            current++
        }
        
        // compose
        let assetExportSession = movieComposition.readyToComposeVideo("\(composedMoviePath)")
        
        // export
        assetExportSession.exportAsynchronouslyWithCompletionHandler({() -> Void in
            
            print("Finish writing")
            
            // delete images that use in generating movie
            self.deleteFiles()
            
            success()
            
        })
        
    }
    
   
}
