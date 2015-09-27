//
//  SettingViewController.swift
//  teiten
//
//  Created by nakajijapan on 12/21/14.
//  Copyright (c) 2014 net.nakajijapan. All rights reserved.
//

import Cocoa
import AVFoundation

enum ScreenResolution:Int {
    case size1280x720 = 0, size320x180, size640x360
    
    func toSize() -> CGSize {
        switch self {
        case .size320x180:
            return CGSize(width: 320, height: 180)
        case size640x360:
            return CGSize(width: 640, height: 360)
        case .size1280x720:
            return CGSize(width: 1280, height: 720)
        }
    }
    
    func toSessionPreset() -> String! {
        switch self {
        case .size320x180:
            return AVCaptureSessionPreset320x240
        case size640x360:
            return AVCaptureSessionPreset640x480
        case .size1280x720:
            return AVCaptureSessionPreset1280x720
        }
    }
}

class SettingViewController: NSViewController {
    
    @IBOutlet var matrix:NSMatrix!
    @IBOutlet var matrixForResolution:NSMatrix!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        
        let timeInterval = NSUserDefaults.standardUserDefaults().integerForKey("TIMEINTERVAL")
        if timeInterval == 10 {
            self.matrix.setSelectionFrom(0, to: 0, anchor: 0, highlight: true)
        } else {
            self.matrix.setSelectionFrom(0, to: 1, anchor: 0, highlight: true)
        }
        
        
        let screenResolution = NSUserDefaults.standardUserDefaults().integerForKey("SCREENRESOLUTION")
        self.matrixForResolution.setSelectionFrom(0, to: screenResolution, anchor: 0, highlight: true)
    }
    
    @IBAction func changeCheckbox(sender:NSMatrix) {
        
        var timeInterval = 10
        switch (sender.selectedRow) {
        case 0:
            timeInterval = 10
        case 1:
            timeInterval = 60
        default:
            break
        }
        
        let userInfo = ["timeInterval": timeInterval]
        let n = NSNotification(name: "changeTimeInterval", object: self, userInfo: userInfo)
        NSNotificationCenter.defaultCenter().postNotification(n)
        
    }
    
    @IBAction func didChangeCheckboxForResolution(sender:NSMatrix) {
        
        let screenResolution = ScreenResolution(rawValue: sender.selectedRow)!
        let userInfo = ["screenResolution": screenResolution.rawValue]
        let notification = NSNotification(name: "didChangeScreenResolution", object: self, userInfo: userInfo)
        NSNotificationCenter.defaultCenter().postNotification(notification)
        
    }
    
    @IBAction func dissmiss(sender: AnyObject) {
        self.dismissController(self)
    }
    
}
