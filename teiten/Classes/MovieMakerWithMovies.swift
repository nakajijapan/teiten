//
//  MovieMakerWithMovies.swift
//  Teiten
//
//  Created by nakajijapan on 2015/10/01.
//  Copyright (c) 2015 net.nakajijapan. All rights reserved.
//

import Foundation
import AVFoundation
import CoreMedia
import CoreVideo
import CoreGraphics
import NKJMovieComposer

protocol MovieMakerWithMoviesDelegate {
    func movieMakerDidAddObject(current: Int, total: Int)
}

class MovieMakerWithMovies: NSObject {
    
    var delegate:MovieMakerWithMoviesDelegate?
    var size:NSSize!
    var files = [String]()
    var dates = [NSDate]()
    
    
    override init() {
        super.init()
        self.setMovieInfo()
    }
    
    // MARK: - File Util
    
    func setMovieInfo() {
        
        // get home directory path
        let homeDir = "\(kAppHomePath)/videos"
        let fileManager = NSFileManager.defaultManager()
        let paths = try! fileManager.contentsOfDirectoryAtPath(homeDir)
        
        for path in paths {
            
            if path.hasSuffix("DS_Store") {
                continue
            }
           
            // Creation Date
            let attributes = try! NSFileManager.defaultManager().attributesOfItemAtPath("\(homeDir)/\(path)")
            let createDateStirng = attributes[NSFileCreationDate] as! NSDate
            self.dates.append(createDateStirng)
            
            // File Path
            self.files.append("\(homeDir)/\(path)")
        }
        
    }
    
    func deleteFiles() {
        
        // get home directory path
        let homeDir = "\(kAppHomePath)/videos"
        let fileManager = NSFileManager.defaultManager()
        let list = try! fileManager.contentsOfDirectoryAtPath(homeDir)
        
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
        
        // generate parent layer
        let layerRoot  = CALayer()
        let layerVideo = CALayer()
        layerRoot.frame   = CGRect(x: 0.0, y: 0.0, width: self.size.width, height: self.size.height)
        layerVideo.frame  = CGRect(x: 0.0, y: 0.0, width: self.size.width, height: self.size.height)
        layerRoot.addSublayer(layerVideo)

        
        let movieComposition = NKJMovieComposer()
        movieComposition.videoComposition.renderSize = CGSize(width: self.size.width, height: self.size.height)

        for i in 0..<self.files.count {

            let beforeTimeDuration = movieComposition.currentTimeDuration
            let moviePath = self.files[i]
            
            // movie
            let movieURL = NSURL(fileURLWithPath: moviePath)
            //let layerInstruction = movieComposition.addVideo(movieURL)
            _ = movieComposition.addVideo(movieURL)
            
            self.delegate?.movieMakerDidAddObject(i + 1, total: self.files.count)
            
            // today
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
            
            // text layer
            let textLayer = CATextLayer()
            textLayer.frame = CGRect(x: self.size.width - 400.0 - 10.0, y: 10.0, width: 400.0, height: 52.0)
            textLayer.string = dateFormatter.stringFromDate(self.dates[i])
            textLayer.fontSize = 48.0
            textLayer.alignmentMode = kCAAlignmentRight
            textLayer.foregroundColor = NSColor.whiteColor().CGColor
            textLayer.shouldRasterize = true
            textLayer.opacity = 0.0
            layerRoot.addSublayer(textLayer)

            // animation
            let offsetTimeDuration = CMTimeSubtract(movieComposition.currentTimeDuration, beforeTimeDuration)
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.beginTime     = (i == 0) ? AVCoreAnimationBeginTimeAtZero : CMTimeGetSeconds(beforeTimeDuration)
            animation.duration      = CMTimeGetSeconds(offsetTimeDuration)
            animation.repeatCount   = 1
            animation.autoreverses  = false
            animation.fromValue     = NSNumber(float: 1.0)
            animation.toValue       = NSNumber(float: 1.0)
            animation.removedOnCompletion = false
            textLayer.addAnimation(animation, forKey:"hide")

        }
        
        
        // animation
        movieComposition.videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: layerVideo, inLayer: layerRoot)
        
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
