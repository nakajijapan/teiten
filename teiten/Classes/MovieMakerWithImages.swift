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
import AppKit

class MovieMakerWithImages: NSObject, MovieCreatable, FileDeletable {
    
    // FileOperatable
    var baseDirectoryPath = "\(kAppHomePath)/images"
    
    // MovieCreatable
    typealias FileListType = NSImage
    var size = NSSize()
    var files = [FileListType]()
    var delegate:MovieMakerDelegate?
    
    override init() {
        super.init()
        self.initImageInfo()
    }
    
    //MARK: - File 
    
    func initImageInfo() {
        
        let fileManager = FileManager.default
        let list:Array = try! fileManager.contentsOfDirectory(atPath: self.baseDirectoryPath)

        for path in list {
            print("path = \(self.baseDirectoryPath)/\(path)")
            
            if path.hasSuffix("DS_Store") {
                continue
            }
            
            let image = NSImage(contentsOfFile: "\(self.baseDirectoryPath)/\(path)")!
            self.files.append(image)
        }
        
    }
    
    //MARK: - movie
    
    func generateMovie(_ composedMoviePath:String, success: @escaping (() -> Void)) {
        
        print("writeImagesAsMovie \(#line) path = file://\(composedMoviePath)")
        let images = self.files
        
        // delete file if file already exists
        let fileManager = FileManager.default;
        if fileManager.fileExists(atPath: composedMoviePath) {
            
            do {
                try fileManager.removeItem(atPath: composedMoviePath)
            } catch let error as NSError {
                print("failed to make directory: \(error.description)");
            }
            
        }
        
        // Target Saving File
        let url = URL(fileURLWithPath: "\(composedMoviePath)")
        
        var videoWriter: AVAssetWriter!
        do {
            videoWriter = try AVAssetWriter(outputURL: url, fileType: AVFileTypeQuickTimeMovie)
        } catch let error as NSError {
            print("failed to create AssetWriter: \(error.description)");
        }
        
        //-----------------------------------
        // AVAssetWriterInput
        
        let videoSettings: [String : AnyObject] = [
            AVVideoCodecKey: AVVideoCodecH264 as AnyObject,
            AVVideoWidthKey: self.size.width as AnyObject,
            AVVideoHeightKey: self.size.height as AnyObject]
        
        
        let writerInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
        videoWriter.add(writerInput)
        
        
        //-----------------------------------
        // AVAssetWriterInputPixelBufferAdaptor
        
        let formatTypeKey = kCVPixelBufferPixelFormatTypeKey as NSString as String
        let widthKey = kCVPixelBufferWidthKey as NSString as String
        let heightKey = kCVPixelBufferHeightKey as NSString as String
        
        let attributes: [String : AnyObject] = [
            formatTypeKey: Int(kCVPixelFormatType_32ARGB) as AnyObject,
            widthKey:      self.size.width as AnyObject,
            heightKey:     self.size.height as AnyObject,
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
        
        videoWriter.startSession(atSourceTime: kCMTimeZero)
        
        
        //-----------------------------------
        // Add Image
        var frameCount:Int64 = 0
        let durationForEachImage:Int64 = 1
        let fps64:Int64 = 48
        var frameTime:CMTime = kCMTimeZero
        
        var current = 1
        
        for nsImage in images {
            
            print("writeImagesAsMovie \(#line) - \(adaptor.assetWriterInput.isReadyForMoreMediaData)")
            
            if adaptor.assetWriterInput.isReadyForMoreMediaData {
                
                print("------------------------ writeImagesAsMovie - \(frameCount)------------------------")
                
                frameTime = CMTimeMake(frameCount * 12 * durationForEachImage, Int32(fps64))
                
                let cgFirstImage:CGImage? = self.convertNSImageToCGImage(nsImage)
                
                let buffer:CVPixelBuffer = self.pixelBufferFromCGImage(cgFirstImage!)
                let result:Bool = adaptor.append(buffer, withPresentationTime: frameTime)
                if result == false {
                    print("failed to append buffer")
                }
                
                
                frameCount += 1
                
                self.delegate?.movieMakerDidAddObject(current, total: images.count)
                current += 1
                
            }
            
            
        }

        writerInput.markAsFinished()
        videoWriter.endSession(atSourceTime: frameTime)
        videoWriter.finishWriting { () -> Void in

            print("Finish writing")
            
            // remove images that use in generating movie
            self.removeFiles(path: self.baseDirectoryPath)
            
            success()
        }
        
    }
    
    // MARK: - Private Methods
    
    func convertNSImageToCGImage(_ image:NSImage) -> CGImage? {
        
        let imageData:Data? = image.tiffRepresentation
        if imageData == nil {
            return nil
        }
        
        let cfImageData:CFData? = imageData as CFData!
        let imageSource:CGImageSource = CGImageSourceCreateWithData(cfImageData!, nil)!
        let cgimage:CGImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)!
        
        return cgimage
    }
    
    func pixelBufferFromCGImage(_ image: CGImage) -> CVPixelBuffer {
        
        let options:NSDictionary = NSDictionary(dictionary: [
            kCVPixelBufferCGImageCompatibilityKey : true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true]
        )
        let cfoptions:CFDictionary = options as CFDictionary
        var unmanagedPixelBuffer:CVPixelBuffer? = nil
        
        // memo
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            image.width,
            image.height,
            kCVPixelFormatType_32ARGB,
            cfoptions,
            &unmanagedPixelBuffer // UnsafeMutablePointer<CVPixelBuffer?>
        )
        
        let pixelBuffer:CVPixelBuffer = unmanagedPixelBuffer!
        
        // Lock
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let pxdata:UnsafeMutableRawPointer = CVPixelBufferGetBaseAddress(pixelBuffer)!
        
        let colorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue
        
        var context = CGContext(
            data: pxdata,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: image.width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        );
        
        let height:CGFloat = CGFloat(image.height)
        let width:CGFloat  = CGFloat(image.width)
        
        // Image had been reversed because of this
        //let flipHorizontal:CGAffineTransform = CGAffineTransformMake(-1.0, 0.0, 0.0, 1.0, width, 0.0);
        //CGContextConcatCTM(context, flipHorizontal);
        
        context?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // UnLock
        context = nil
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}
