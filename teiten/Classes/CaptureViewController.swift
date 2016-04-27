//
//  CaptureViewController.swift
//  test
//
//  Created by nakajijapan on 2014/07/11.
//  Copyright (c) 2014 net.nakajijapan. All rights reserved.
//

import Cocoa
import AVFoundation
import CoreMedia
import CoreVideo
import QuartzCore

import RxSwift
import RxCocoa
import RxBlocking

let kAppHomePath = "\(NSHomeDirectory())/Teiten"
let kAppMoviePath = "\(NSHomeDirectory())/Movies/\(NSBundle.mainBundle().bundleIdentifier!)"

class CaptureViewController: NSViewController, MovieMakerWithImagesDelegate, MovieMakerWithMoviesDelegate, NSTableViewDataSource, NSTableViewDelegate, AVCaptureFileOutputRecordingDelegate {
    
    let disposeBag = DisposeBag()
    
    // timer
    var timer:NSTimer!
    var timeInterval = 0
    @IBOutlet var countDownLabel:NSTextField!
    
    // resolution
    var screenResolution = ScreenResolution.size1280x720.rawValue
    
    // resouce type
    var resourceType = ResourceType.Image.rawValue
    
    
    // background
    @IBOutlet var backgroundView:NSView!
    
    // camera
    var previewView:NSView!
    
    // image
    var captureSession:AVCaptureSession!
    var videoStillImageOutput:AVCaptureStillImageOutput!
    
    // movie
    var videoMovieFileOutput:AVCaptureMovieFileOutput!
    
    // disable connecting camera
    @IBOutlet var disableConnectingCaptureDeviceImageView:NSImageView!

    
    @IBOutlet var tableView:NSTableView!
    var entity = FileEntity()
    
    
    // indicator
    @IBOutlet weak var indicator: NSProgressIndicator!
    
    // MARK: - LifeCycle

    override func viewDidLoad() {
        
        // make working directory
        let fileManager = NSFileManager.defaultManager()
        
        do {
            try fileManager.createDirectoryAtPath("\(kAppHomePath)/images", withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("failed to make directory. error: \(error.description)")
        }
        
        do {
            try fileManager.createDirectoryAtPath("\(kAppHomePath)/videos", withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("failed to make directory. error: \(error.description)")
        }
        
        do {
            try fileManager.createDirectoryAtPath("\(kAppMoviePath)", withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("failed to make directory error: \(error.description)")
        }

        // Default Setting
        self.initDefaultSettings()
        
        // Subscribe NSUserDefaults
        self.initSubscribeNSuserDefaults()
        
        // AVCaptureDevice
        guard let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) else {
            self.disableConnectingCaptureDevice()
            return
        }

        // Image
        let videoInput:AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: device)
        } catch _ {
            self.disableConnectingCaptureDevice()
            return
        }

        self.videoStillImageOutput = AVCaptureStillImageOutput()
        
        // Movie
        self.videoMovieFileOutput = AVCaptureMovieFileOutput()
        let maxDuration = CMTime(
            seconds: 3.0,          // recording time
            preferredTimescale: 24 // frame buffer
        )
        self.videoMovieFileOutput.maxRecordedDuration = maxDuration
        self.videoMovieFileOutput.minFreeDiskSpaceLimit = 1024 * 1024
        
        self.captureSession = AVCaptureSession()

        if self.captureSession.canAddInput(videoInput) {
            self.captureSession.addInput(videoInput as AVCaptureInput)
        } else {
            self.disableConnectingCaptureDevice()
            return
        }
        
        if self.captureSession.canAddOutput(self.videoStillImageOutput) {
            self.captureSession.addOutput(self.videoStillImageOutput)
        } else {
            self.disableConnectingCaptureDevice()
            return
        }
        
        if self.captureSession.canAddOutput(self.videoMovieFileOutput) {
            self.captureSession.addOutput(self.videoMovieFileOutput)
        } else {
            self.disableConnectingCaptureDevice()
            return
        }
        
        
        let audioCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        let audioInput = try! AVCaptureDeviceInput(device: audioCaptureDevice) //[AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];

        if self.captureSession.canAddInput(audioInput) {
            self.captureSession.addInput(audioInput)
        } else {
            self.disableConnectingCaptureDevice()
            return
        }
        
        // AVCaptureSessionPreset1280x720
        self.captureSession.sessionPreset = ScreenResolution(rawValue: 0)!.toSessionPreset()
        
        // Preview Layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer.frame = CGRect(x: 0, y: 0, width: 640, height: 360)
        
        self.previewView = NSView(frame: NSRect(x:0, y: 0, width: 640, height: 360))
        self.previewView.layer = previewLayer
        
        self.backgroundView.addSubview(self.previewView, positioned: NSWindowOrderingMode.Below, relativeTo: self.backgroundView)
        
        // start
        self.captureSession.startRunning()
        
        // setting drag type allowed
        let types = [NSImage.imageTypes().first!, NSFilenamesPboardType]
        self.tableView.registerForDraggedTypes(types)
        self.tableView.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal: false)
        

        
        self.initCountDown()
        

    }
    
    func disableConnectingCaptureDevice() {
        self.backgroundView.hidden = true
        self.disableConnectingCaptureDeviceImageView.hidden = false
    }

    func initDefaultSettings() {

        self.timeInterval = NSUserDefaults.standardUserDefaults().integerForKey("TIMEINTERVAL")
        if self.timeInterval < 1 {
            self.timeInterval = 10
            NSUserDefaults.standardUserDefaults().setInteger(self.timeInterval, forKey: "TIMEINTERVAL")
        }
        
        self.screenResolution = NSUserDefaults.standardUserDefaults().integerForKey("SCREENRESOLUTION")
        
        NSUserDefaults.standardUserDefaults().setInteger(self.screenResolution, forKey: "SCREENRESOLUTION")
        
        self.resourceType = NSUserDefaults.standardUserDefaults().integerForKey("RESOURCETYPE")

    }
    
    func initCountDown() {

        // TimeInterval
        _ = Observable<Int>.interval(1.0, scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe({ event in
                
                self.countDownLabel.stringValue = String(self.timeInterval)
                
            })
            .addDisposableTo(disposeBag)
        
        // CountDownLabel
        self.countDownLabel.rx_observe(String.self, "stringValue")
            .subscribe({ (string) -> Void in
                
                if self.timeInterval > 0 {
                    
                    self.timeInterval -= 1
                    
                } else if (self.timeInterval == 0) {
                    
                    self.timeInterval = NSUserDefaults.standardUserDefaults().integerForKey("TIMEINTERVAL")
                    
                    if self.resourceType == ResourceType.Image.rawValue {
                        self.pushButtonCaptureImage(nil)
                    } else {
                        self.captureMovie(nil)
                    }
                    
                    
                }
                
            })
            .addDisposableTo(disposeBag)

    }
    
    // MARK: - NSUserDefaults
    func initSubscribeNSuserDefaults() {
        
        NSUserDefaults.standardUserDefaults()
            .rx_observe(Int.self, "TIMEINTERVAL")
            .subscribeNext({ (value) -> Void in
                
                if value != nil {
                    self.timeInterval = value!
                }
                
            }).addDisposableTo(disposeBag)
        
        NSUserDefaults.standardUserDefaults()
            .rx_observe(Int.self, "SCREENRESOLUTION")
            .subscribeNext({ (value) -> Void in

                if value != nil {
                    self.screenResolution = value!
                }

            })
            .addDisposableTo(disposeBag)
        
        NSUserDefaults.standardUserDefaults()
            .rx_observe(Int.self, "RESOURCETYPE")
            .subscribeNext({ (value) -> Void in
                
                if value != nil {
                    self.resourceType = value!
                }

            })
            .addDisposableTo(disposeBag)

    }

    // MARK: - Actions
    
    @IBAction func pushButtonCaptureImage(sender:AnyObject!) {
        
        let connection = self.videoStillImageOutput.connections[0] as! AVCaptureConnection
        
        self.videoStillImageOutput.captureStillImageAsynchronouslyFromConnection(connection, completionHandler: {(sambleBuffer, erro) -> Void in
            
            let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sambleBuffer)
            let tmpImage = NSImage(data: data)!
            let targetSize = ScreenResolution(rawValue: self.screenResolution)!.toSize()
            let image = self.imageFromSize(tmpImage, size: targetSize)
            
            // convert to jpeg for writing file
            let data2 = image.TIFFRepresentation
            let bitmapImageRep = NSBitmapImageRep.imageRepsWithData(data2!)[0] as! NSBitmapImageRep
            let properties = [NSImageInterlaced: NSNumber(bool: true)]
            let resizedData:NSData? = bitmapImageRep.representationUsingType(NSBitmapImageFileType.NSJPEGFileType, properties: properties)
            
            // reload table
            self.entity.loadImage(image, data: resizedData!)
            
            dispatch_async(dispatch_get_main_queue(), {() -> Void in
                self.tableView.reloadData()
            })
            
        })
    }
    
    func imageFromSize(sourceImage:NSImage, size:NSSize) -> NSImage! {
        
        // extract NSBitmapImageRep from sourceImage, and take out CGImage
        let image = NSBitmapImageRep(data: sourceImage.TIFFRepresentation!)?.CGImage!
        
        // generate new bitmap size
        let width  = Int(size.width)
        let height = Int(size.height)
        let bitsPerComponent = Int(8)
        let bytesPerRow = Int(4) * width
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.PremultipliedLast.rawValue
        let bitmapContext = CGBitmapContextCreate(nil, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo)!
        
        // write source image to bitmap
        let bitmapRect = NSMakeRect(0.0, 0.0, size.width, size.height)
        
        CGContextDrawImage(bitmapContext, bitmapRect, image)
        
        // convert NSImage to bitmap
        let newImageRef = CGBitmapContextCreateImage(bitmapContext)!
        let newImage = NSImage(CGImage: newImageRef, size: size)
        
        return newImage
        
    }
    
    @IBAction func pushButtonCreateMovie(sender:AnyObject!) {
        
        // save path
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let date = NSDate()
        let path = "\(kAppMoviePath)/\(dateFormatter.stringFromDate(date)).mov"
        
        if self.resourceType == ResourceType.Image.rawValue {
            
            self.indicatorStart()

            let movieMaker = MovieMakerWithImages()
            movieMaker.delegate = self
            movieMaker.size = ScreenResolution(rawValue: self.screenResolution)?.toSize()
            movieMaker.writeImagesAsMovie(toPath: path) { () -> Void in
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    self.indicatorStop()

                })
                
            }
            
        } else {
            
            self.indicatorStart()
            
            let movieMaker = MovieMakerWithMovies()
            movieMaker.delegate = self
            movieMaker.size = ScreenResolution(rawValue: self.screenResolution)?.toSize()
            movieMaker.composeMovies(path, success: { () -> Void in
                
                self.indicatorStop()

            })

        }
        
    }
    
    func indicatorStart() {
        self.indicator.hidden = false
        self.indicator.doubleValue = 0
        self.indicator.startAnimation(self.indicator)
    }
    
    func indicatorStop() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            // Indicator Stop
            self.indicator.doubleValue = 100.0
            self.indicator.stopAnimation(self.indicator)
            self.indicator.hidden = true
            
            // Alert
            let alert = NSAlert()
            alert.alertStyle = NSAlertStyle.InformationalAlertStyle
            alert.messageText = "Complete!!"
            alert.informativeText = "finished generating movie"
            alert.runModal()
        })
    }
    
    func captureMovie(sender:AnyObject!) {
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let dateString = dateFormatter.stringFromDate(NSDate())
        let pathString = "\(kAppHomePath)/videos/\(dateString).mov"
        let schemePathString = "file://\(pathString)"

        if NSFileManager.defaultManager().fileExistsAtPath(pathString) {
            try! NSFileManager.defaultManager().removeItemAtPath(pathString)
        }
        
        // start recording
        self.videoMovieFileOutput.startRecordingToOutputFileURL(NSURL(string: schemePathString), recordingDelegate: self)
        
    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        print("Saved: \(outputFileURL)")
    }
    
    // MARK: - MovieMakerDelegate, MovieMakerWithMoviesDelegate
    
    // add Object
    func movieMakerDidAddObject(current: Int, total: Int) {
        let nst = NSThread(target:self, selector:#selector(CaptureViewController.countOne(_:)), object:["current": current, "total": total])
        nst.start()
    }
    
    // refrect count number to label
    func countOne(params: [String:Int]) {
        let delta = 100.0 / Double(params["total"]!)
        self.indicator.incrementBy(Double(delta))
    }
    
    
    // MARK: - NSTableView data source
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return 1
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeViewWithIdentifier("imageCell", owner: self)
        let imageView = view!.viewWithTag(1) as! NSImageView
        imageView.image = self.entity.image
        imageView.alphaValue = 0.6
        return view
    }
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 80
    }
    
    // MARK: - Drag
    
    func tableView(tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        return self.entity
    }
    
}