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
let kAppMoviePath = "\(NSHomeDirectory())/Movies/\(Bundle.main.bundleIdentifier!)"

public class CaptureViewController: NSViewController, MovieMakerDelegate, NSTableViewDataSource, NSTableViewDelegate, AVCaptureFileOutputRecordingDelegate {
    
    let disposeBag = DisposeBag()
    
    // timer
    var timer: Timer!
    var timeInterval = 0
    @IBOutlet var countDownLabel: NSTextField!
    @IBOutlet weak var previewImageScrollView: NSScrollView!

    // resolution
    var screenResolution = ScreenResolution.size1280x720.rawValue
    
    // resouce type
    var resourceType = ResourceType.Image.rawValue
    
    // Outlets
    @IBOutlet var backgroundView:NSView!
    @IBOutlet var cannotConnectCameraView: NSView!
    @IBOutlet weak var createMovieButton: NSButton!
    @IBOutlet weak var captureImageButton: NSButton!
    
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

    override public func viewDidLoad() {

        // Initialize
        self.initDirectories()
        self.initDefaultSettings()
        self.initSubscribeNSuserDefaults()
        self.initCannotConnectCameraView()

        // AVCaptureDevice
        guard let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else {
            self.cannotConnectCameraViewHidden(hidden: false)
            return
        }

        // Image
        let videoInput:AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: device)
        } catch _ {
            self.cannotConnectCameraViewHidden(hidden: false)
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
            self.cannotConnectCameraViewHidden(hidden: false)
            return
        }
        
        if self.captureSession.canAddOutput(self.videoStillImageOutput) {
            self.captureSession.addOutput(self.videoStillImageOutput)
        } else {
            self.cannotConnectCameraViewHidden(hidden: false)
            return
        }
        
        if self.captureSession.canAddOutput(self.videoMovieFileOutput) {
            self.captureSession.addOutput(self.videoMovieFileOutput)
        } else {
            self.cannotConnectCameraViewHidden(hidden: false)
            return
        }
        
        
        let audioCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        let audioInput = try! AVCaptureDeviceInput(device: audioCaptureDevice) //[AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];

        if self.captureSession.canAddInput(audioInput) {
            self.captureSession.addInput(audioInput)
        } else {
            self.cannotConnectCameraViewHidden(hidden: false)
            return
        }
        
        // AVCaptureSessionPreset1280x720
        self.captureSession.sessionPreset = ScreenResolution(rawValue: 0)!.toSessionPreset()
        
        // Preview Layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer?.frame = CGRect(x: 0, y: 0, width: 640, height: 360)
        
        self.previewView = NSView(frame: NSRect(x:0, y: 0, width: 640, height: 360))
        self.previewView.layer = previewLayer
        
        self.backgroundView.addSubview(self.previewView, positioned: NSWindowOrderingMode.below, relativeTo: self.backgroundView)
        
        // start
        self.captureSession.startRunning()
        
        // setting drag type allowed
        let types = [NSImage.imageTypes().first!, NSFilenamesPboardType]
        self.tableView.register(forDraggedTypes: types)
        self.tableView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false)
        
        self.initCountDown()
    }
    
    func cannotConnectCameraViewHidden(hidden:Bool) {

        self.countDownLabel.isHidden = !hidden
        self.previewImageScrollView.isHidden = !hidden
        self.cannotConnectCameraView.isHidden = hidden

        self.createMovieButton.isEnabled = hidden
        self.captureImageButton.isEnabled = hidden

    }
    
    func initCannotConnectCameraView() {

        self.cannotConnectCameraView.isHidden = true
        self.backgroundView.addSubview(self.cannotConnectCameraView)
        self.cannotConnectCameraView.translatesAutoresizingMaskIntoConstraints = false
        let views = ["cannotConnectCameraView": self.cannotConnectCameraView]
        self.backgroundView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:|[cannotConnectCameraView]|",
            options: NSLayoutFormatOptions.alignAllCenterX,
            metrics: nil,
            views: views)
        )
        self.view.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "H:|[cannotConnectCameraView]|",
            options: NSLayoutFormatOptions.alignAllCenterX,
            metrics: nil,
            views: views)
        )

    }

    func initDirectories() {

        // make working directory
        let fileManager = FileManager.default
        
        do {
            try fileManager.createDirectory(atPath: "\(kAppHomePath)/images", withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("failed to make directory. error: \(error.description)")
        }
        
        do {
            try fileManager.createDirectory(atPath: "\(kAppHomePath)/videos", withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("failed to make directory. error: \(error.description)")
        }
        
        do {
            try fileManager.createDirectory(atPath: "\(kAppMoviePath)", withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("failed to make directory error: \(error.description)")
        }
    }

    func initDefaultSettings() {

        self.timeInterval = UserDefaults.standard.integer(forKey: "TIMEINTERVAL")
        if self.timeInterval < 1 {
            self.timeInterval = 10
            UserDefaults.standard.set(self.timeInterval, forKey: "TIMEINTERVAL")
        }
        
        self.screenResolution = UserDefaults.standard.integer(forKey: "SCREENRESOLUTION")
        
        UserDefaults.standard.set(self.screenResolution, forKey: "SCREENRESOLUTION")
        
        self.resourceType = UserDefaults.standard.integer(forKey: "RESOURCETYPE")

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
                    
                    self.timeInterval = UserDefaults.standard.integerForKey("TIMEINTERVAL")
                    
                    if self.resourceType == ResourceType.Image.rawValue {
                        self.captureImage()
                    } else {
                        self.captureMovie(nil)
                    }
                    
                    
                }
                
            })
            .addDisposableTo(disposeBag)

    }
    
    // MARK: - NSUserDefaults
    func initSubscribeNSuserDefaults() {
        
        UserDefaults.standard
            .rx_observe(Int.self, "TIMEINTERVAL")
            .subscribeNext({ (value) -> Void in
                
                if value != nil {
                    self.timeInterval = value!
                }
                
            }).addDisposableTo(disposeBag)
        
        UserDefaults.standard
            .rx_observe(Int.self, "SCREENRESOLUTION")
            .subscribeNext({ (value) -> Void in

                if value != nil {
                    self.screenResolution = value!
                }

            })
            .addDisposableTo(disposeBag)
        
        UserDefaults.standard
            .rx_observe(Int.self, "RESOURCETYPE")
            .subscribeNext({ (value) -> Void in
                
                if value != nil {
                    self.resourceType = value!
                }

            })
            .addDisposableTo(disposeBag)

    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate
    
    public func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        print("Saved: \(outputFileURL)")
    }
    
    // MARK: - MovieMakerDelegate
    
    // add Object
    func movieMakerDidAddObject(current: Int, total: Int) {
        let nst = Thread(target:self, selector:#selector(CaptureViewController.countOne(_:)), object:["current": current, "total": total])
        nst.start()
    }
    
    // refrect count number to label
    func countOne(params: [String:Int]) {
        let delta = 100.0 / Double(params["total"]!)
        self.indicator.increment(by: Double(delta))
    }
    
    
    // MARK: - NSTableView data source
    
    public func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return 1
    }
    
    public func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.make(withIdentifier: "imageCell", owner: self)
        let imageView = view!.viewWithTag(1) as! NSImageView
        imageView.image = self.entity.image
        imageView.alphaValue = 0.6
        return view
    }
    
    public func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 80
    }
    
    // MARK: - Drag
    
    public func tableView(tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        return self.entity
    }
    
    // MARK: - Actions
    
    @IBAction func captureImageButtonDidClick(sender:AnyObject?) {
        self.captureImage()
    }
    
    @IBAction func createMovieButtonDidClick(sender:AnyObject?) {
        self.createMovie()
    }


    // MARK: - Public Methods
    
    public func captureImage() {
        
        guard self.videoStillImageOutput != nil else {
            return
        }
        
        let connection = self.videoStillImageOutput.connections[0] as! AVCaptureConnection
        
        self.videoStillImageOutput.captureStillImageAsynchronously(from: connection, completionHandler: {(sambleBuffer, erro) -> Void in
            
            let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sambleBuffer)!
            let tmpImage = NSImage(data: data)!
            let targetSize = ScreenResolution(rawValue: self.screenResolution)!.toSize()
            let image = self.imageFromSize(sourceImage: tmpImage, size: targetSize)!
            
            // convert to jpeg for writing file
            let data2 = image.tiffRepresentation
            let bitmapImageRep = NSBitmapImageRep.imageReps(with: data2!)[0] as! NSBitmapImageRep
            let properties = [NSImageInterlaced: NSNumber(value: true)]
            let resizedData:Data? = bitmapImageRep.representationUsingType(NSBitmapImageFileType.NSJPEGFileType, properties: properties)
            
            // reload table
            self.entity.loadImage(image: image, data: resizedData!)
            
            DispatchQueue.main.asynchronously(execute: {() -> Void in
                self.tableView.reloadData()
            })
            
        })
        
    }
    
    public func createMovie() {
        
        // save path
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let date = Date()
        let path = "\(kAppMoviePath)/\(dateFormatter.string(from: date)).mov"

        self.indicatorStart()
        
        if self.resourceType == ResourceType.Image.rawValue {
            let movieMaker = MovieMakerWithImages()
            movieMaker.size = ScreenResolution(rawValue: self.screenResolution)!.toSize()
            movieMaker.delegate = self
            movieMaker.generateMovie(composedMoviePath: path) { () -> Void in
                
                dispatch_get_main_queue().asynchronously(execute: { () -> Void in
                    
                    self.indicatorStop()
                    
                })
                
            }        } else {
            let movieMaker = MovieMakerWithMovies()
            movieMaker.size = ScreenResolution(rawValue: self.screenResolution)!.toSize()
            movieMaker.delegate = self
            movieMaker.generateMovie(composedMoviePath: path) { () -> Void in
                
                DispatchQueue.main.asynchronously(execute: { () -> Void in
                    
                    self.indicatorStop()
                    
                })
                
            }        }

    }
    
    // MARK: - Private Methods

    func imageFromSize(sourceImage:NSImage, size:NSSize) -> NSImage! {
        
        // extract NSBitmapImageRep from sourceImage, and take out CGImage
        let image = NSBitmapImageRep(data: sourceImage.tiffRepresentation!)?.cgImage!
        
        // generate new bitmap size
        let width  = Int(size.width)
        let height = Int(size.height)
        let bitsPerComponent = Int(8)
        let bytesPerRow = Int(4) * width
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        let bitmapContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)!
        
        // write source image to bitmap
        let bitmapRect = NSMakeRect(0.0, 0.0, size.width, size.height)
        
        CGContextDrawImage(bitmapContext, bitmapRect, image)
        
        // convert NSImage to bitmap
        let newImageRef = bitmapContext.makeImage()!
        let newImage = NSImage(cgImage: newImageRef, size: size)
        
        return newImage
        
    }
    
    func indicatorStart() {
        self.indicator.isHidden = false
        self.indicator.doubleValue = 0
        self.indicator.startAnimation(self.indicator)
    }
    
    func indicatorStop() {
        DispatchQueue.main.asynchronously(execute: { () -> Void in
            
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
    
    func captureMovie(sender: AnyObject!) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let dateString = dateFormatter.string(from: Date())
        let pathString = "\(kAppHomePath)/videos/\(dateString).mov"
        let schemePathString = "file://\(pathString)"
        
        if FileManager.default.fileExists(atPath: pathString) {
            try! FileManager.default.removeItem(atPath: pathString)
        }
        
        // start recording
        self.videoMovieFileOutput.startRecording(toOutputFileURL: URL(string: schemePathString), recordingDelegate: self)
        
    }
}
