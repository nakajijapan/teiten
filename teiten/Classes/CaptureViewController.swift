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

class CaptureViewController: NSViewController, MovieMakerDelegate, NSTableViewDataSource, NSTableViewDelegate {

    // timer
    var timer:NSTimer!
    var timeInterval = 0
    @IBOutlet var countDownLabel:NSTextField!

    // resolution
    var screenResolution = ScreenResolution.size1280x720.rawValue


    // background
    @IBOutlet var backgroundView:NSView!

    // camera
    var previewView:NSView!

    // image
    var captureSession:AVCaptureSession!
    var videoOutput:AVCaptureStillImageOutput!

    @IBOutlet var tableView:NSTableView!
    var entity = FileEntity()

    // indicator
    @IBOutlet weak var indicator: NSProgressIndicator!

    // MARK: - LifeCycle

    override func viewDidLoad() {

        // create working directory
        let fileManager = NSFileManager.defaultManager()
        var error:NSError?
        if !fileManager.createDirectoryAtPath("\(kAppHomePath)/images", withIntermediateDirectories: true, attributes: nil, error: &error) {
            println("failed creating directory: \(error!.description)")
        }

        if !fileManager.createDirectoryAtPath("\(kAppMoviePath)", withIntermediateDirectories: true, attributes: nil, error: &error) {
            println("failed creating directory: \(error!.description)")
        }

        // settings
        self.timeInterval = NSUserDefaults.standardUserDefaults().integerForKey("TIMEINTERVAL")
        if self.timeInterval < 1 {
            self.timeInterval = 10
            NSUserDefaults.standardUserDefaults().setInteger(self.timeInterval, forKey: "TIMEINTERVAL")
        }

        self.screenResolution = NSUserDefaults.standardUserDefaults().integerForKey("SCREENRESOLUTION")

        NSUserDefaults.standardUserDefaults().setInteger(self.screenResolution, forKey: "SCREENRESOLUTION")
        //println("self.screenResolution = \(self.screenResolution)")

        // timer
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "timerAction:", userInfo: nil, repeats: true)
        self.timer.fire()

        // notifications
        self.initNotification()

        // Video
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        let videoInput = AVCaptureDeviceInput.deviceInputWithDevice(device, error: nil) as! AVCaptureDeviceInput
        var videoOutput = AVCaptureStillImageOutput()
        self.videoOutput = videoOutput

        self.captureSession = AVCaptureSession()
        self.captureSession.addInput(videoInput as AVCaptureInput)
        self.captureSession.addOutput(videoOutput)

        // AVCaptureSessionPreset1280x720
        self.captureSession.sessionPreset = ScreenResolution(rawValue: 0)!.toSessionPreset()

        let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer.frame = CGRect(x: 0, y: 0, width: 640, height: 360)

        self.previewView = NSView(frame: NSRect(x:0, y: 0, width: 640, height: 360))
        self.previewView.layer = previewLayer

        self.backgroundView.addSubview(self.previewView, positioned: NSWindowOrderingMode.Below, relativeTo: self.backgroundView)

        // start
        self.captureSession.startRunning()

        // set the drag type that allow
        let types:[AnyObject] = [NSImage.imageTypes(), NSFilenamesPboardType, kUTTypeURL]
        self.tableView.registerForDraggedTypes(types)
        self.tableView.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal: false)
    }


    // MARK: - notifications

    func initNotification() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "updateTimeInterval:", name: "changeTimeInterval", object: nil)
        nc.addObserver(self, selector: "updateScreenResolution:", name: "didChangeScreenResolution", object: nil)
    }

    func updateTimeInterval(sender:NSNotification) {
        let interval = sender.userInfo!["timeInterval"] as! NSNumber
        self.timeInterval = interval.integerValue
        NSUserDefaults.standardUserDefaults().setInteger(interval.integerValue, forKey: "TIMEINTERVAL")
    }


    func updateScreenResolution(sender:NSNotification) {

        let screenResolution = sender.userInfo!["screenResolution"] as! NSNumber
        self.screenResolution = screenResolution.integerValue
        NSUserDefaults.standardUserDefaults().setInteger(self.screenResolution, forKey: "SCREENRESOLUTION")

    }

    // MARK: - Actions

    func timerAction(sender:AnyObject!) {

        self.countDownLabel.stringValue = String(self.timeInterval)

        if self.timeInterval > 0 {
            self.timeInterval--
        } else if (self.timeInterval == 0) {
            self.timeInterval = NSUserDefaults.standardUserDefaults().integerForKey("TIMEINTERVAL")
            self.pushButtonCaptureImage(nil)
        }
    }

    @IBAction func pushButtonCaptureImage(sender:AnyObject!) {

        let connection = self.videoOutput.connections[0] as! AVCaptureConnection

        self.videoOutput.captureStillImageAsynchronouslyFromConnection(connection, completionHandler: {(sambleBuffer, erro) -> Void in

            let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sambleBuffer)
            let tmpImage = NSImage(data: data)!
            let targetSize = ScreenResolution(rawValue: self.screenResolution)!.toSize()
            let size = tmpImage.size
            let image = self.imageFromSize(tmpImage, size: targetSize)

            // convert to jpeg
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

        // get NSBitmapImageRep from sourceImage, convert to CGImage
        let image = NSBitmapImageRep(data: sourceImage.TIFFRepresentation!)?.CGImage!

        // create bitmat for new size
        let width  = Int(size.width)
        let height = Int(size.height)
        let bitsPerComponent = Int(8)
        let bytesPerRow = Int(4) * width
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)

        let bitmapContext = CGBitmapContextCreate(nil, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo)!

        // write souceimage on bitmap
        let bitmapRect = NSMakeRect(0.0, 0.0, size.width, size.height)

        CGContextDrawImage(bitmapContext, bitmapRect, image)

        // convert bitmat to NSImage
        let newImageRef = CGBitmapContextCreateImage(bitmapContext)!
        let newImage = NSImage(CGImage: newImageRef, size: size)

        return newImage

    }

    @IBAction func pushButtonCreateMovie(sender:AnyObject!) {

        var movieMaker = MovieMaker()
        movieMaker.delegate = self
        movieMaker.size = ScreenResolution(rawValue: self.screenResolution)?.toSize()

        // images
        var images = movieMaker.getImageList()

        // save path
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let date = NSDate()
        let path = "\(kAppMoviePath)/\(dateFormatter.stringFromDate(date)).mov"

        // indicator start
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


    // MARK: - MovieMakerDelegate

    func movieMakerDidAddImage(current: Int, total: Int) {
        var thread = NSThread(target:self, selector:"countOne:", object:["current": current, "total": total])
        thread.start()
    }

    func countOne(params: [String:Int]) {
        let delta = 100.0 / Double(params["total"]!)
        self.indicator.incrementBy(Double(delta))
    }

    // MARK: - NSTableView data source

    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return 1
    }

    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var view = tableView.makeViewWithIdentifier("imageCell", owner: self) as! NSView
        var imageView = view.viewWithTag(1) as! NSImageView
        imageView.image = self.entity.image
        imageView.alphaValue = 0.6

        return view
    }

    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 80
    }

    // MARK: - Drag
    func tableView(tableView: NSTableView, draggingSession session: NSDraggingSession, endedAtPoint screenPoint: NSPoint, operation: NSDragOperation) {

    }

    func tableView(tableView: NSTableView, draggingSession session: NSDraggingSession, willBeginAtPoint screenPoint: NSPoint, forRowIndexes rowIndexes: NSIndexSet) {

    }

    func tableView(tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        return self.entity
    }

}
