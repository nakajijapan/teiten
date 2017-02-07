//
//  SettingViewController.swift
//  teiten
//
//  Created by nakajijapan on 2014/12/24.
//  Copyright (c) 2014 net.nakajijapan. All rights reserved.
//

import Cocoa
import AVFoundation

enum ScreenResolution:Int {
    case size1280x720, size320x180, size640x360
    
    func toSize() -> CGSize {
        switch self {
        case .size320x180:
            return CGSize(width: 320, height: 180)
        case .size640x360:
            return CGSize(width: 640, height: 360)
        case .size1280x720:
            return CGSize(width: 1280, height: 720)
        }
    }
    
    func toString() -> String {
        switch self {
        case .size320x180:
            return "size320x180"
        case .size640x360:
            return "size640x360"
        case .size1280x720:
            return "size1280x720"
        }
    }
    
    func toSessionPreset() -> String! {
        switch self {
        case .size320x180:
            return AVCaptureSessionPreset320x240
        case .size640x360:
            return AVCaptureSessionPreset640x480
        case .size1280x720:
            return AVCaptureSessionPreset1280x720
        }
    }
}

enum ResourceType:Int {
    case Image = 0, Movie
}

class SettingViewController: NSViewController {
    
    @IBOutlet var matrix:NSMatrix!
    @IBOutlet var matrixForResolution:NSMatrix!
    @IBOutlet var matrixForResourceType:NSMatrix!
    
    override func viewWillAppear() {
        
        let timeInterval = UserDefaults.standard.integer(forKey: "TIMEINTERVAL")
        if timeInterval == 10 {
            self.matrix.setSelectionFrom(0, to: 0, anchor: 0, highlight: true)
        } else {
            self.matrix.setSelectionFrom(0, to: 1, anchor: 0, highlight: true)
        }
        
        let screenResolution = UserDefaults.standard.integer(forKey: "SCREENRESOLUTION")
        self.matrixForResolution.setSelectionFrom(0, to: screenResolution, anchor: 0, highlight: true)
        
        let resourceType = UserDefaults.standard.integer(forKey: "RESOURCETYPE")
        self.matrixForResourceType.setSelectionFrom(0, to: resourceType, anchor: 0, highlight: true)
    }
    
    @IBAction func timeIntervalMatrixDidChangeValue(sender:NSMatrix) {
        
        var timeInterval = 10
        switch (sender.selectedRow) {
        case 0:
            timeInterval = 10
        case 1:
            timeInterval = 60
        default:
            break
        }
        
        UserDefaults.standard.set(timeInterval, forKey: "TIMEINTERVAL")
        
    }
    
    @IBAction func resolutionMatrixDidChangeValue(sender:NSMatrix) {

        let screenResolution = ScreenResolution(rawValue: sender.selectedRow)!
        UserDefaults.standard.set(screenResolution.rawValue, forKey: "SCREENRESOLUTION")

    }
    
    @IBAction func resourceTypeMatrixDidChangeValue(sender: NSMatrix) {

        let resourceType = ResourceType(rawValue: sender.selectedRow)!
        UserDefaults.standard.set(resourceType.rawValue, forKey: "RESOURCETYPE")

    }
    
    @IBAction func dissmiss(_ sender: Any) {
        self.dismiss(self)
    }
    
}
