//
//  CaptureViewController.swift
//  test
//
//  Created by nakajijapan on 2014/07/11.
//  Copyright (c) 2014年 net.nakajijapan. All rights reserved.
//

import Cocoa
import AVFoundation
import CoreMedia
import CoreVideo
import QuartzCore

let kAppHomePath = "\(NSHomeDirectory())/Teiten"
let kAppMoviePath = "\(NSHomeDirectory())/Movies/Teiten"


class CaptureViewController: NSViewController, MovieMakerDelegate, NSTableViewDataSource, NSTableViewDelegate, AVCaptureFileOutputRecordingDelegate {
    
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
            try fileManager.createDirectoryAtPath("\(kAppHomePath)/movies", withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("failed to make directory. error: \(error.description)")
        }
        
        do {
            try fileManager.createDirectoryAtPath("\(kAppMoviePath)", withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("failed to make directory error: \(error.description)")
        }
        
        //-------------------------------------------------
        // initialize - settings
        self.timeInterval = NSUserDefaults.standardUserDefaults().integerForKey("TIMEINTERVAL")
        if self.timeInterval < 1 {
            self.timeInterval = 10
            NSUserDefaults.standardUserDefaults().setInteger(self.timeInterval, forKey: "TIMEINTERVAL")
        }
        
        self.screenResolution = NSUserDefaults.standardUserDefaults().integerForKey("SCREENRESOLUTION")
        
        NSUserDefaults.standardUserDefaults().setInteger(self.screenResolution, forKey: "SCREENRESOLUTION")
        print("self.screenResolution = \(self.screenResolution)")
        
        self.resourceType = NSUserDefaults.standardUserDefaults().integerForKey("RESOURCETYPE")
        
        //-------------------------------------------------
        // initialize - timer
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "timerAction:", userInfo: nil, repeats: true)
        self.timer.fire()
        
        // notifications
        self.initNotification()
        
        //-------------------------------------------------
        // initialize
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        // Image
        let videoInput = try! AVCaptureDeviceInput(device: device)
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
        }
        
        if self.captureSession.canAddOutput(self.videoStillImageOutput) {
            self.captureSession.addOutput(self.videoStillImageOutput)
        }
        
        if self.captureSession.canAddOutput(self.videoMovieFileOutput) {
            self.captureSession.addOutput(self.videoMovieFileOutput)
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
        
        //-------------------------------------------------
        // 許可するドラッグタイプを設定
        let types = [NSImage.imageTypes().first!, NSFilenamesPboardType]
        self.tableView.registerForDraggedTypes(types)
        self.tableView.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal: false)
    }
    

    
    
    // MARK: - notifications
    func initNotification() {
        let notification = NSNotificationCenter.defaultCenter()
        notification.addObserver(self, selector: "updateTimeInterval:", name: "SettingDidChangeTimeInterval", object: nil)
        notification.addObserver(self, selector: "updateScreenResolution:", name: "SettingDidChangeScreenResolution", object: nil)
        notification.addObserver(self, selector: "updateResurceType:", name: "SettingDidChangeResourceType", object: nil)
    }
    
    func updateTimeInterval(sender:NSNotification) {
        let value = sender.userInfo!["timeInterval"] as! NSNumber
        self.timeInterval = value.integerValue
        NSUserDefaults.standardUserDefaults().setInteger(value.integerValue, forKey: "TIMEINTERVAL")
    }
    
    
    func updateScreenResolution(sender:NSNotification) {
        
        let value = sender.userInfo!["screenResolution"] as! NSNumber
        self.screenResolution = value.integerValue
        NSUserDefaults.standardUserDefaults().setInteger(value.integerValue, forKey: "SCREENRESOLUTION")
        
    }
    
    func updateResurceType(sender:NSNotification) {
        
        let value = sender.userInfo!["resourceType"] as! NSNumber
        self.resourceType = value.integerValue
        NSUserDefaults.standardUserDefaults().setInteger(value.integerValue, forKey: "RESOURCETYPE")
        
   }
    
    // MARK: - Actions
    
    func timerAction(sender:AnyObject!) {
        
        self.countDownLabel.stringValue = String(self.timeInterval)
        
        if self.timeInterval > 0 {
            self.timeInterval--
        } else if (self.timeInterval == 0) {
            self.timeInterval = NSUserDefaults.standardUserDefaults().integerForKey("TIMEINTERVAL")
            
            if self.resourceType == ResourceType.Image.rawValue {
                self.pushButtonCaptureImage(nil)
            } else {
                self.pushButtonCaptureMovie(nil)
            }
            

        }
    }
    
    
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
        
        let movieMaker = MovieMaker()
        movieMaker.delegate = self
        movieMaker.size = ScreenResolution(rawValue: self.screenResolution)?.toSize()
        
        // images
        let images = movieMaker.getImageList()
        
        // save path
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let date = NSDate()
        let path = "\(kAppMoviePath)/\(dateFormatter.stringFromDate(date)).mov"
        
        // Indicator Start
        self.indicator.hidden = false
        self.indicator.doubleValue = 0
        self.indicator.startAnimation(self.indicator)
        
        // generate movie
        movieMaker.writeImagesAsMovie(images, toPath: path) { () -> Void in
            
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
        
    }
    
    func pushButtonCaptureMovie(sender:AnyObject!) {
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let dateString = dateFormatter.stringFromDate(NSDate())
        let pathString = "\(kAppHomePath)/movies/\(dateString).mov"
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
    
    // MARK: - MovieMakerDelegate
    
    // add Image
    func movieMakerDidAddImage(current: Int, total: Int) {
        let nst = NSThread(target:self, selector:"countOne:", object:["current": current, "total": total])
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
    
    // MARK: - Segue
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        print("prepareForSegue: \(segue.identifier)")
        print(sender)
        
    }
    
}