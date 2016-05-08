//
//  CaptureDeviceManager.swift
//  Teiten
//
//  Created by nakajijapan on 2016/05/08.
//  Copyright © 2016年 net.nakajijapan. All rights reserved.
//

import Foundation
import AVFoundation

public class VideoDeviceManager {
    
    var captureSession:AVCaptureSession!
    
    init(captureSession: AVCaptureSession) {
        self.captureSession = captureSession
    }
    
    public class func defaultDevice() -> AVCaptureDevice! {
        return AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    }
    
    public class func videoDevices() -> [AVCaptureDevice] {
        
        var captureDevices = [AVCaptureDevice]()
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        
        devices.forEach { (device) in
            let captureDevice = device as! AVCaptureDevice
            print("device = \(captureDevice.localizedName) \(captureDevice.uniqueID)")
            captureDevices.append(captureDevice)
        }
     
        return captureDevices
    }
    
    func switchDevice(uniqueID:String, currentCaptureInput:AVCaptureDeviceInput) throws {
        
        var captureDevice:AVCaptureDevice?
        for device in self.dynamicType.videoDevices() {
            if device.uniqueID == uniqueID {
                captureDevice = device
                break
            }
        }

        self.captureSession.beginConfiguration()
        
        let videoInput:AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: captureDevice)
        } catch _ {
            throw NSError(domain: TeitenError.errorDomain!, code: -1, userInfo: ["description": "AVCaptureDevice notfound"])
        }
 
        self.captureSession.removeInput(currentCaptureInput)
        if self.captureSession.canAddInput(videoInput) {
            self.captureSession.addInput(videoInput as AVCaptureInput)
        } else {
            throw NSError(domain: TeitenError.errorDomain!, code: -1, userInfo: ["description": "AVCaptureDevice cannot add \(videoInput)"])
        }
        
        self.captureSession.commitConfiguration()
        
    }
    
}