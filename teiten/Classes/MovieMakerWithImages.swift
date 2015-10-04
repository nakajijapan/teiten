//
//  MovieMaker.swift
//  teiten
//
//  Created by nakajijapan on 2014/12/24.
//  Copyright (c) 2014 net.nakajijapan. All rights reserved.
//

import AVFoundation
import CoreMedia
import CoreVideo
import CoreGraphics
import Foundation

protocol MovieMakerWithImagesDelegate {
    func movieMakerDidAddObject(current: Int, total: Int)
}

class MovieMakerWithImages: NSObject {
    
    var delegate:MovieMakerWithImagesDelegate?
    var size:NSSize!
    
    //MARK: - File Util
    
    func getImageList() -> [NSImage] {
        
        // get home directory path
        let homeDir = "\(kAppHomePath)/images"
        let fileManager = NSFileManager.defaultManager()
        let list:Array = try! fileManager.contentsOfDirectoryAtPath(homeDir)
        var files:[NSImage] = []
        
        for path in list {
            print("path = \(homeDir)/\(path)")
            
            if path.hasSuffix("DS_Store") {
                continue
            }
            
            let image = NSImage(contentsOfFile: "\(homeDir)/\(path)")!
            files.append(image)
        }
        
        return files
    }
    
    func deleteFiles() {
        
        // get home directory path
        let homeDir = "\(kAppHomePath)/images"
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
    
    func writeImagesAsMovie(images:[NSImage], toPath path:String, success: (() -> Void)) {
        
        print("writeImagesAsMovie \(__LINE__) path = file://\(path)")
        
        // delete file if file already exists
        let fileManager = NSFileManager.defaultManager();
        if fileManager.fileExistsAtPath(path) {
            
            do {
                try fileManager.removeItemAtPath(path)
            } catch let error as NSError {
                print("failed to make directory: \(error.description)");
            }
            
        }
        
        // Target Saving File
        let url = NSURL(fileURLWithPath: "\(path)")
        
        var videoWriter: AVAssetWriter!
        do {
            videoWriter = try AVAssetWriter(URL: url, fileType: AVFileTypeQuickTimeMovie)
        } catch let error as NSError {
            print("failed to create AssetWriter: \(error.description)");
        }
        
        //-----------------------------------
        // AVAssetWriterInput
        
        let videoSettings: [String : AnyObject] = [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: self.size.width,
            AVVideoHeightKey: self.size.height]
        
        
        let writerInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
        videoWriter.addInput(writerInput)
        
        
        //-----------------------------------
        // AVAssetWriterInputPixelBufferAdaptor
        
        let formatTypeKey = kCVPixelBufferPixelFormatTypeKey as NSString as String
        let widthKey = kCVPixelBufferWidthKey as NSString as String
        let heightKey = kCVPixelBufferHeightKey as NSString as String
        
        let attributes: [String : AnyObject] = [
            formatTypeKey: Int(kCVPixelFormatType_32ARGB),
            widthKey:      self.size.width,
            heightKey:     self.size.height,
        ]
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: attributes)
        
        // fixes all errors
        writerInput.expectsMediaDataInRealTime = true;
        
        //-----------------------------------
        // start generate
        let start = videoWriter.startWriting()
        if !start {
            print("failed writing");
        }
        print("Session started? \(start)");
        
        videoWriter.startSessionAtSourceTime(kCMTimeZero)
        
        
        //-----------------------------------
        // Add Image
        var frameCount:Int64 = 0
        let durationForEachImage:Int64 = 1
        let fps64:Int64 = 48
        var frameTime:CMTime = kCMTimeZero
        
        var current = 1
        
        for nsImage in images {
            
            print("writeImagesAsMovie \(__LINE__) - \(adaptor.assetWriterInput.readyForMoreMediaData)")
            
            if adaptor.assetWriterInput.readyForMoreMediaData {
                
                print("------------------------ writeImagesAsMovie - \(frameCount)------------------------")
                
                frameTime = CMTimeMake(frameCount * 12 * durationForEachImage, Int32(fps64))
                
                let cgFirstImage:CGImage? = self.convertNSImageToCGImage(nsImage)
                
                let buffer:CVPixelBufferRef = self.pixelBufferFromCGImage(cgFirstImage!)
                let result:Bool = adaptor.appendPixelBuffer(buffer, withPresentationTime: frameTime)
                if result == false {
                    print("failed to append buffer")
                }
                
                
                frameCount++
                
                self.delegate?.movieMakerDidAddObject(current, total: images.count)
                current++
                
            }
            
            
        }

        writerInput.markAsFinished()
        videoWriter.endSessionAtSourceTime(frameTime)
        videoWriter.finishWritingWithCompletionHandler { () -> Void in
            print("Finish writing")
            
            // delete images that use in generating movie
            self.deleteFiles()
            
            success()
        }
        
    }
    
    // MARK: - Private Methods
    
    func convertNSImageToCGImage(image:NSImage) -> CGImage? {
        
        let imageData:NSData? = image.TIFFRepresentation
        if imageData == nil {
            return nil
        }
        
        let cfImageData:CFData? = imageData as CFData!
        let imageSource:CGImageSource = CGImageSourceCreateWithData(cfImageData!, nil)!
        let cgimage:CGImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)!
        
        return cgimage
    }
    
    func pixelBufferFromCGImage(image: CGImage) -> CVPixelBuffer {
        
        let options:NSDictionary = NSDictionary(dictionary: [
            kCVPixelBufferCGImageCompatibilityKey : true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true]
        )
        let cfoptions:CFDictionary = options as CFDictionary
        var unmanagedPixelBuffer:CVPixelBuffer? = nil
        
        // memo
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            CGImageGetWidth(image),
            CGImageGetHeight(image),
            kCVPixelFormatType_32ARGB,
            cfoptions,
            &unmanagedPixelBuffer // UnsafeMutablePointer<CVPixelBuffer?>
        )
        
        let pixelBuffer:CVPixelBuffer = unmanagedPixelBuffer!
        
        // Lock
        CVPixelBufferLockBaseAddress(pixelBuffer, 0)
        
        let pxdata:UnsafeMutablePointer<()> = CVPixelBufferGetBaseAddress(pixelBuffer)
        
        let colorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB()!
        let bitmapInfo = CGImageAlphaInfo.PremultipliedFirst.rawValue
        
        var context = CGBitmapContextCreate(
            pxdata,
            CGImageGetWidth(image),
            CGImageGetHeight(image),
            8,
            CGImageGetWidth(image) * 4,
            colorSpace,
            bitmapInfo
        );
        
        let height:CGFloat = CGFloat(CGImageGetHeight(image))
        let width:CGFloat  = CGFloat(CGImageGetWidth(image))
        
        // Image had been reversed because of this
        //let flipHorizontal:CGAffineTransform = CGAffineTransformMake(-1.0, 0.0, 0.0, 1.0, width, 0.0);
        //CGContextConcatCTM(context, flipHorizontal);
        
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), image)
        
        // UnLock
        context = nil
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0)
        
        return pixelBuffer
    }
}
