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

fileprivate extension NSTouchBarCustomizationIdentifier {
    static let touchBar = NSTouchBarCustomizationIdentifier(Bundle.main.bundleIdentifier!)
}

fileprivate extension NSTouchBarItemIdentifier {
    static let capture = NSTouchBarItemIdentifier("\(Bundle.main.bundleIdentifier!).TouchBarItem.capture")
    static let share = NSTouchBarItemIdentifier("\(Bundle.main.bundleIdentifier!).TouchBarItem.share")
    static let size = NSTouchBarItemIdentifier("\(Bundle.main.bundleIdentifier!).TouchBarItem.size")
}

class CaptureViewController: NSViewController, MovieMakerDelegate, AVCaptureFileOutputRecordingDelegate, NSTableViewDataSource, NSTableViewDelegate {
 
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
    var previewView: NSView!
    
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
        initDirectories()
        initDefaultSettings()
        initSubscribeNSuserDefaults()
        initCannotConnectCameraView()

        // AVCaptureDevice
        guard let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else {
            cannotConnectCameraViewHidden(hidden: false)
            return
        }

        // Image
        let videoInput:AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: device)
        } catch _ {
            cannotConnectCameraViewHidden(hidden: false)
            return
        }

        videoStillImageOutput = AVCaptureStillImageOutput()
        
        // Movie
        videoMovieFileOutput = AVCaptureMovieFileOutput()
        let maxDuration = CMTime(
            seconds: 4.0,          // recording time
            preferredTimescale: 24 // frame buffer
        )
        videoMovieFileOutput.maxRecordedDuration = maxDuration
        videoMovieFileOutput.minFreeDiskSpaceLimit = 1024 * 1024
        
        captureSession = AVCaptureSession()
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput as AVCaptureInput)
        } else {
            cannotConnectCameraViewHidden(hidden: false)
            return
        }
        
        if captureSession.canAddOutput(videoStillImageOutput) {
            captureSession.addOutput(videoStillImageOutput)
        } else {
            cannotConnectCameraViewHidden(hidden: false)
            return
        }
        
        if captureSession.canAddOutput(videoMovieFileOutput) {
            captureSession.addOutput(videoMovieFileOutput)
        } else {
            cannotConnectCameraViewHidden(hidden: false)
            return
        }
        
        
        let audioCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        let audioInput = try! AVCaptureDeviceInput(device: audioCaptureDevice) //[AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];

        if captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        } else {
            cannotConnectCameraViewHidden(hidden: false)
            return
        }
        
        // AVCaptureSessionPreset1280x720
        captureSession.sessionPreset = ScreenResolution(rawValue: 0)!.toSessionPreset()
        
        // Preview Layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer?.frame = CGRect(x: 0, y: 0, width: 640, height: 360)
        
        previewView = NSView(frame: NSRect(x:0, y: 0, width: 640, height: 360))
        previewView.layer = previewLayer
        
        backgroundView.addSubview(previewView, positioned: NSWindowOrderingMode.below, relativeTo: backgroundView)
        
        // start
        captureSession.startRunning()
        
        // setting drag type allowed
        let types = [NSImage.imageTypes().first!, NSFilenamesPboardType]
        tableView.register(forDraggedTypes: types)
        tableView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false)
        
        initCountDown()
    }
    
    func cannotConnectCameraViewHidden(hidden:Bool) {

        countDownLabel.isHidden = !hidden
        previewImageScrollView.isHidden = !hidden
        cannotConnectCameraView.isHidden = hidden

        createMovieButton.isEnabled = hidden
        captureImageButton.isEnabled = hidden

    }
    
    func initCannotConnectCameraView() {

        cannotConnectCameraView.isHidden = true
        backgroundView.addSubview(cannotConnectCameraView)
        cannotConnectCameraView.translatesAutoresizingMaskIntoConstraints = false
        let views = ["cannotConnectCameraView": cannotConnectCameraView] as [String: Any]
        backgroundView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:|[cannotConnectCameraView]|",
            options: NSLayoutFormatOptions.alignAllCenterX,
            metrics: nil,
            views: views)
        )
        view.addConstraints(NSLayoutConstraint.constraints(
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

        timeInterval = UserDefaults.standard.integer(forKey: "TIMEINTERVAL")
        if timeInterval < 1 {
            timeInterval = 10
            UserDefaults.standard.set(self.timeInterval, forKey: "TIMEINTERVAL")
        }
        
        screenResolution = UserDefaults.standard.integer(forKey: "SCREENRESOLUTION")
        
        UserDefaults.standard.set(self.screenResolution, forKey: "SCREENRESOLUTION")
        
        resourceType = UserDefaults.standard.integer(forKey: "RESOURCETYPE")

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
        countDownLabel
            .rx
            .observe(String.self, "stringValue")
            .subscribe(
                onNext: { (string) in
                    if self.timeInterval > 0 {
                        
                        self.timeInterval -= 1
                        
                    } else if (self.timeInterval == 0) {
                        
                        self.timeInterval = UserDefaults.standard.integer(forKey: "TIMEINTERVAL")
                        
                        if self.resourceType == ResourceType.Image.rawValue {
                            self.captureImage()
                        } else {
                            self.captureMovie(sender: nil)
                        }
                        
                        
                    }
            },
                onError: nil,
                onCompleted: nil,
                onDisposed: nil)
            .addDisposableTo(disposeBag)

    }
    
    // MARK: - NSUserDefaults
    func initSubscribeNSuserDefaults() {
        
        UserDefaults.standard.rx
            .observe(Int.self, "TIMEINTERVAL")
            .subscribe(
                onNext: { (value: Int?) in
                    if let value = value {
                        self.timeInterval = value
                    }
            },
                onError: nil,
                onCompleted: nil,
                onDisposed: nil)
            .addDisposableTo(disposeBag)
        
        UserDefaults.standard
            .rx
            .observe(Int.self, "SCREENRESOLUTION")
            .subscribe(
                onNext: { (value: Int?) in
                    if let value = value {
                        self.screenResolution = value
                    }
            },
                onError: nil,
                onCompleted: nil,
                onDisposed: nil)
            .addDisposableTo(disposeBag)
        
        UserDefaults.standard
            .rx.observe(Int.self, "RESOURCETYPE")
            .subscribe(
                onNext: { (value: Int?) in
                    if let value = value {
                        self.resourceType = value
                    }
            },
                onError: nil,
                onCompleted: nil,
                onDisposed: nil)
            
            .addDisposableTo(disposeBag)

    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate

    public func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        print("Saved: \(outputFileURL)")

    }
    
    // MARK: - MovieMakerDelegate
    
    // add Object
    func movieMakerDidAddObject(_ current: Int, total: Int) {
        let nst = Thread(target:self, selector:#selector(self.countOne(_:)), object:["current": current, "total": total])
        nst.start()
    }
    
    // refrect count number to label
    func countOne(_ params: [String:Int]) {
        let delta = 100.0 / Double(params["total"]!)
        indicator.increment(by: Double(delta))
    }
    
    // MARK: - Actions
    
    @IBAction func captureImageButtonDidClick(_ sender: Any) {
        captureImage()
    }
    
    @IBAction func createMovieButtonDidClick(_ sender: Any) {
        createMovie()
    }

    // MARK: - Public Methods
    
    public func captureImage() {
        
        guard videoStillImageOutput != nil else {
            return
        }
        
        let connection = videoStillImageOutput.connections[0] as! AVCaptureConnection
        
        videoStillImageOutput.captureStillImageAsynchronously(from: connection, completionHandler: {(sambleBuffer, erro) -> Void in
            
            let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sambleBuffer)!
            let tmpImage = NSImage(data: data)!
            let targetSize = ScreenResolution(rawValue: self.screenResolution)!.toSize()
            let image = self.imageFromSize(sourceImage: tmpImage, size: targetSize)!
            
            // convert to jpeg for writing file
            let data2 = image.tiffRepresentation
            let bitmapImageRep = NSBitmapImageRep.imageReps(with: data2!)[0] as! NSBitmapImageRep
            let properties = [NSImageInterlaced: NSNumber(value: true)]
            
            let resizedData:Data? = bitmapImageRep.representation(using: NSBitmapImageFileType.JPEG, properties: properties)
            
            // reload table
            self.entity.loadImage(image: image, data: resizedData!)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        })
        
    }
    
    public func createMovie() {
        
        // save path
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let date = Date()
        let path = "\(kAppMoviePath)/\(dateFormatter.string(from: date)).mov"

        indicatorStart()
        
        if resourceType == ResourceType.Image.rawValue {
            let movieMaker = MovieMakerWithImages()
            movieMaker.size = ScreenResolution(rawValue: screenResolution)!.toSize()
            movieMaker.delegate = self
            movieMaker.generateMovie(path) {
                DispatchQueue.main.async {
                    self.indicatorStop()
                }
            }
        } else {
            let movieMaker = MovieMakerWithMovies()
            movieMaker.size = ScreenResolution(rawValue: 0)!.toSize() // fixed
            movieMaker.delegate = self
            movieMaker.generateMovie(path) {
                DispatchQueue.main.async {
                    self.indicatorStop()
                }
            }
        }

    }
    
    // MARK: - Private Methods

    func imageFromSize(sourceImage:NSImage, size:NSSize) -> NSImage! {
        
        // extract NSBitmapImageRep from sourceImage, and take out CGImage
        let image = NSBitmapImageRep(data: sourceImage.tiffRepresentation!)!.cgImage!
        
        // generate new bitmap size
        let width  = Int(size.width)
        let height = Int(size.height)
        let bitsPerComponent = Int(8)
        let bytesPerRow = Int(4) * width
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        let bitmapContext = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
            )!
        
        // write source image to bitmap
        let bitmapRect = NSMakeRect(0.0, 0.0, size.width, size.height)
        
        bitmapContext.draw(image, in: bitmapRect)
        
        // convert NSImage to bitmap
        let newImageRef = bitmapContext.makeImage()!
        let newImage = NSImage(cgImage: newImageRef, size: size)
        
        return newImage
        
    }
    
    func indicatorStart() {
        indicator.isHidden = false
        indicator.doubleValue = 0
        indicator.startAnimation(self.indicator)
    }
    
    func indicatorStop() {
        DispatchQueue.main.async {
            
            // Indicator Stop
            self.indicator.doubleValue = 100.0
            self.indicator.stopAnimation(self.indicator)
            self.indicator.isHidden = true
            
            // Alert
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "Complete!!"
            alert.informativeText = "finished generating movie"
            alert.runModal()
        }
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
        videoMovieFileOutput.startRecording(toOutputFileURL: URL(string: schemePathString), recordingDelegate: self)
        
    }
    
    // MARK: - NSTableView data source
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.make(withIdentifier: "imageCell", owner: self)
        let imageView = view!.viewWithTag(1) as! NSImageView
        imageView.image = entity.image
        imageView.alphaValue = 0.6
        return view
    }
    
    public func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 80
    }
    
    // MARK: - Drag
    
    public func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        return self.entity
    }
}


// MARK: -  NSTouchBar
extension CaptureViewController {
    
    // MARK: - TouchBar
    @available(OSX 10.12.2, *)
    override open func makeTouchBar() -> NSTouchBar? {
        
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = .touchBar
        touchBar.defaultItemIdentifiers = [.capture, .share, .size]
        
        return touchBar
        
    }
    
}

// MARK: - NSTouchBarDelegate
extension CaptureViewController: NSTouchBarDelegate {
    
    @available(OSX 10.12.2, *)
    public func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem? {
        
        print("\(identifier)")
        
        switch identifier {
        case NSTouchBarItemIdentifier.capture:
            
            let button = NSButton(image: NSImage(named: "button_capture_image")!, target: self, action: #selector(captureButtonDidTap(_:)))
            button.bezelColor = NSColor(red:0.35, green:0.61, blue:0.35, alpha:1.00)
            
            
            let touchBarItem = NSCustomTouchBarItem(identifier: identifier)
            touchBarItem.view = button
            return touchBarItem
            
        case NSTouchBarItemIdentifier.size:
            
            let customActionItem = NSCustomTouchBarItem(identifier: identifier)
            let segmentedControl = NSSegmentedControl(
                labels: [
                    ScreenResolution.size1280x720.toString(),
                    ScreenResolution.size320x180.toString(),
                    ScreenResolution.size640x360.toString(),
                ],
                trackingMode: NSSegmentSwitchTracking.selectOne,
                target: self,
                action: #selector(segmentedControlDidSelect(_:))
            )
            
            let screenResolution = UserDefaults.standard.integer(forKey: "SCREENRESOLUTION")
            segmentedControl.selectedSegment = screenResolution
            customActionItem.view = segmentedControl
            return customActionItem
            
            
        case NSTouchBarItemIdentifier.share:
            
            let services = NSSharingServicePickerTouchBarItem(identifier: identifier)
            services.delegate = self
            
            return services
            
        default:
            return nil
        }
        
    }
    
    func segmentedControlDidSelect(_ sender: NSSegmentedControl) {
        let screenResolution = ScreenResolution(rawValue: sender.selectedSegment)!
        UserDefaults.standard.set(screenResolution.rawValue, forKey: "SCREENRESOLUTION")
    }
    
    func captureButtonDidTap(_ sender: NSButton) {
        captureImage()
    }
    
    
}

// MARK: - NSSharingServicePickerTouchBarItemDelegate
extension CaptureViewController: NSSharingServicePickerTouchBarItemDelegate {

    @available(OSX 10.12.2, *)
    func items(for pickerTouchBarItem: NSSharingServicePickerTouchBarItem) -> [Any] {
        if let image = entity.image {
            return [image]
        }
        return []
    }

}
