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

class MovieMakerWithMovies: NSObject, MovieCreatable, FileDeletable {

    // FileOperatable
    var baseDirectoryPath = "\(kAppHomePath)/videos"
    
    // MovieCreatable
    typealias FileListType = String
    var size = NSSize()
    var files = [FileListType]()
    var delegate:MovieMakerDelegate?

    var dates = [Date]()
    
    
    override init() {
        super.init()
        self.initMovieInfo()
    }
    
    // MARK: - File
    
    func initMovieInfo() {
        
        let fileManager = FileManager.default
        let paths = try! fileManager.contentsOfDirectory(atPath: self.baseDirectoryPath)
        
        for path in paths {
            
            if path.hasSuffix("DS_Store") {
                continue
            }
           
            // Creation Date
            let attributes = try! FileManager.default.attributesOfItem(atPath: "\(self.baseDirectoryPath)/\(path)")
            let createDateStirng = attributes[FileAttributeKey.creationDate] as! Date
            self.dates.append(createDateStirng)
            
            // File Path
            self.files.append("\(self.baseDirectoryPath)/\(path)")
        }
        
    }
    
    //MARK: - movie

    func generateMovie(_ composedMoviePath:String, success: @escaping (() -> Void)) {
        
        // delete file if file already exists
        let fileManager = FileManager.default;
        if fileManager.fileExists(atPath: composedMoviePath) {
            
            do {
                try fileManager.removeItem(atPath: composedMoviePath)
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
            let movieURL = URL(fileURLWithPath: moviePath)
            //let layerInstruction = movieComposition.addVideo(movieURL)
            _ = movieComposition.addVideo(movieURL)
            
            self.delegate?.movieMakerDidAddObject(i + 1, total: self.files.count)
            
            // today
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
            
            // text layer
            let textLayer = CATextLayer()
            textLayer.frame = CGRect(x: self.size.width - 400.0 - 10.0, y: 10.0, width: 400.0, height: 52.0)
            textLayer.string = dateFormatter.string(from: self.dates[i])
            textLayer.fontSize = 48.0
            textLayer.alignmentMode = kCAAlignmentRight
            textLayer.foregroundColor = NSColor.white.cgColor
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
            animation.fromValue     = NSNumber(value: 1.0 as Float)
            animation.toValue       = NSNumber(value: 1.0 as Float)
            animation.isRemovedOnCompletion = false
            textLayer.add(animation, forKey:"hide")

        }
        
        
        // animation
        movieComposition.videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: layerVideo, in: layerRoot)
        
        // compose
        let assetExportSession = movieComposition.readyToComposeVideo("\(composedMoviePath)")
        
        // export
        assetExportSession?.exportAsynchronously(completionHandler: {() -> Void in
            
            print("Finish writing")
            
            // remove images that use in generating movie
            self.removeFiles(path: self.baseDirectoryPath)
            
            success()
            
        })
        
    }
   
}
