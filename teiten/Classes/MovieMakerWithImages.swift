//
//  MovieMaker.swift
//  teiten
//
//  Created by nakajijapan on 2014/12/24.
//  Copyright (c) 2014 net.nakajijapan. All rights reserved.
//

import AppKit
import AVFoundation
import CoreMedia
import CoreVideo
import CoreGraphics

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
        initImageInfo()
    }
    
    //MARK: - File 
    
    func initImageInfo() {
        
        let fileManager = FileManager.default
        let list:Array = try! fileManager.contentsOfDirectory(atPath: baseDirectoryPath)

        for path in list {
            print("path = \(baseDirectoryPath)/\(path)")
            
            if path.hasSuffix("DS_Store") {
                continue
            }
            
            let image = NSImage(contentsOfFile: "\(baseDirectoryPath)/\(path)")!
            files.append(image)
        }
        
    }
    
    //MARK: - movie
    
    func generateMovie(_ composedMoviePath:String, success: @escaping (() -> Void)) {
        
        print("writeImagesAsMovie \(#line) path = file://\(composedMoviePath)")
        let images = files
        
        // delete file if file already exists
        let fileManager = FileManager.default
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
        
        let videoSettings = [
            AVVideoCodecKey: AVVideoCodecH264 as AnyObject,
            AVVideoWidthKey: size.width as AnyObject,
            AVVideoHeightKey: size.height as AnyObject
        ] as [String: Any]
        
        let writerInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
        videoWriter.add(writerInput)
        
        
        //-----------------------------------
        // AVAssetWriterInputPixelBufferAdaptor
        
        let formatTypeKey = kCVPixelBufferPixelFormatTypeKey as NSString as String
        let widthKey = kCVPixelBufferWidthKey as NSString as String
        let heightKey = kCVPixelBufferHeightKey as NSString as String
        
        let attributes = [
            formatTypeKey: Int(kCVPixelFormatType_32ARGB),
            widthKey: size.width,
            heightKey: size.height,
        ] as [String: Any]
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: attributes)
        
        // fixes all errors
        writerInput.expectsMediaDataInRealTime = true
        
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
        var frameCount: Int64 = 0
        let durationForEachImage: Int64 = 1
        let fps64: Int64 = 48
        var frameTime: CMTime = kCMTimeZero
        
        var current = 1
        
        for nsImage in images {
            
            print("writeImagesAsMovie \(#line) - \(adaptor.assetWriterInput.isReadyForMoreMediaData)")
            
            if adaptor.assetWriterInput.isReadyForMoreMediaData {
                
                print("------------------------ writeImagesAsMovie - \(frameCount)------------------------")
                
                frameTime = CMTimeMake(frameCount * 12 * durationForEachImage, Int32(fps64))
                
                let cgFirstImage = convertNSImageToCGImage(image: nsImage)
                
                let buffer: CVPixelBuffer = self.pixelBufferFromCGImage(image: cgFirstImage!)
                let result: Bool = adaptor.append(buffer, withPresentationTime: frameTime)
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
    
    func convertNSImageToCGImage(image:NSImage) -> CGImage? {
        
        guard let imageData = image.tiffRepresentation else {
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
            image.width,
            image.height,
            kCVPixelFormatType_32ARGB,
            cfoptions,
            &unmanagedPixelBuffer // UnsafeMutablePointer<CVPixelBuffer?>
        )
        
        let pixelBuffer:CVPixelBuffer = unmanagedPixelBuffer!
        
        // Lock
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        //let pxdata:UnsafeMutablePointer<()> = CVPixelBufferGetBaseAddress(pixelBuffer)
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
