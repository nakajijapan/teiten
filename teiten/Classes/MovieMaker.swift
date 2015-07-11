//
//  MovieMaker.swift
//  teiten
//
//  Created by nakajijapan on 12/24/14.
//  Copyright (c) 2014 net.nakajijapan. All rights reserved.
//

import Cocoa
import AVFoundation
import CoreMedia
import CoreVideo
import CoreGraphics
import Foundation

protocol MovieMakerDelegate {
    func movieMakerDidAddImage(current: Int, total: Int)
}

class MovieMaker: NSObject {

    var delegate:MovieMakerDelegate?
    var size:NSSize!
    
    //MARK: - File Util

    func getImageList() -> [NSImage] {
        
        let homeDir = "\(kAppHomePath)/images"
        let fileManager = NSFileManager.defaultManager()
        
        var error:NSError?
        let list:Array = fileManager.contentsOfDirectoryAtPath(homeDir, error: &error)!
        
        var files:[NSImage] = []
        
        for path in list {
            
            if path.hasSuffix("DS_Store") {
                continue
            }
            
            let image = NSImage(contentsOfFile: "\(homeDir)/\(path)")!
            files.append(image)
        }
        
        return files
    }
    
    func deleteFiles() {
        
        let homeDir = "\(kAppHomePath)/images"
        let fileManager = NSFileManager.defaultManager()
        
        var error:NSError?
        let list:Array = fileManager.contentsOfDirectoryAtPath(homeDir, error: &error)!
        
        for path in list {
            fileManager.removeItemAtPath("\(homeDir)/\(path)", error: nil)
        }
    }
    
    //MARK: - movie
    
    func writeImagesAsMovie(images:[NSImage], toPath path:String, success: (() -> Void)) {
        
        // 既にファイルがある場合は削除する
        let fileManager = NSFileManager.defaultManager();
        if fileManager.fileExistsAtPath(path) {
            fileManager.removeItemAtPath(path, error: nil)
        }
        
        // Target Saving File
        let url = NSURL(fileURLWithPath:path)
        
        var error:NSError? = nil
        var videoWriter = AVAssetWriter(URL: url, fileType: AVFileTypeQuickTimeMovie, error: &error)
        
        if error != nil {
            println("error creating AssetWriter: \(error!.description)");
        }
        
        // AVAssetWriterInput
        let videoSettings:[NSObject : AnyObject] = [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: self.size.width,
            AVVideoHeightKey: self.size.height]
        
        
        var writerInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
        videoWriter.addInput(writerInput)
        
        // AVAssetWriterInputPixelBufferAdaptor
        var attributes:Dictionary<NSObject, AnyObject> = [
            NSString(format: kCVPixelBufferPixelFormatTypeKey): NSNumber(unsignedInt: UInt32(kCVPixelFormatType_32ARGB)),
            NSString(format: kCVPixelBufferWidthKey):           NSNumber(unsignedInt: UInt32(self.size.width)),
            NSString(format: kCVPixelBufferHeightKey):          NSNumber(unsignedInt: UInt32(self.size.height)),
        ];
        
        var adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: attributes)

        // fixes all errors
        writerInput.expectsMediaDataInRealTime = true;
        
        // generation
        var start:Bool = videoWriter.startWriting()
        if !start {
            println("failed writing");
        }
        
        videoWriter.startSessionAtSourceTime(kCMTimeZero)
        
        // Add Image
        var frameCount:Int64 = 0
        let durationForEachImage:Int64 = 1
        let fps64:Int64 = 48
        var frameTime:CMTime = kCMTimeZero
        
        var current = 1
        for nsImage in images {
            
            if adaptor.assetWriterInput.readyForMoreMediaData {
                
                frameTime = CMTimeMake(frameCount * 12 * durationForEachImage, Int32(fps64))
                let cgFirstImage:CGImage? = self.convertNSImageToCGImage(nsImage)
                
                var buffer:CVPixelBufferRef = self.pixelBufferFromCGImage(cgFirstImage!)
                let result:Bool = adaptor.appendPixelBuffer(buffer, withPresentationTime: frameTime)
                if result == false {
                    println("failed to append buffer")
                }
                frameCount++
                
                self.delegate?.movieMakerDidAddImage(current, total: images.count)
                current++
            }

        }
        
        writerInput.markAsFinished()
        videoWriter.endSessionAtSourceTime(frameTime)
        
        videoWriter.finishWritingWithCompletionHandler(nil)


        self.deleteFiles()
        
        success()
    }
    
    // MARK: - movie(Private)
    
    func convertNSImageToCGImage(image:NSImage) -> CGImage? {

        let imageData:NSData? = image.TIFFRepresentation
        if imageData == nil {
            return nil
        }
        
        var cfImageData:CFData? = imageData as CFData!
        var imageSource:CGImageSource = CGImageSourceCreateWithData(cfImageData, nil)
        var cgimage:CGImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        
        return cgimage
    }
    
    func pixelBufferFromCGImage(image: CGImage) -> CVPixelBuffer {
        
        let options:NSDictionary = NSDictionary(dictionary: [
            kCVPixelBufferCGImageCompatibilityKey : true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
            ])
        
        let cfoptions:CFDictionary = options as CFDictionary
        var unmanagedPixelBuffer:Unmanaged<CVPixelBuffer>? = nil
        
        let pixelFormat:OSType = UInt32(kCVPixelFormatType_32ARGB)
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            CGImageGetWidth(image),
            CGImageGetHeight(image),
            pixelFormat,
            cfoptions,
            &unmanagedPixelBuffer // UnsafeMutablePointer<Unmanaged<CVPixelBuffer>?>
        )
        
        var pixelBuffer:CVPixelBuffer = Unmanaged<CVPixelBuffer>.takeUnretainedValue(unmanagedPixelBuffer!)()
        
        // Lock
        CVPixelBufferLockBaseAddress(pixelBuffer, 0)
        
        var pxdata:UnsafeMutablePointer<()> = CVPixelBufferGetBaseAddress(pixelBuffer)
        
        var colorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue)
        
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
        
        // because of inverting image
        //let flipHorizontal:CGAffineTransform = CGAffineTransformMake(-1.0, 0.0, 0.0, 1.0, width, 0.0);
        //CGContextConcatCTM(context, flipHorizontal);
        
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), image)

        // UnLock
        context = nil
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0)
        
        return pixelBuffer
    }
}
