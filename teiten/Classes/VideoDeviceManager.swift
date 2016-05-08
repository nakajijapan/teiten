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
    
    static let sharedManager = VideoDeviceManager()
    var captureSession = AVCaptureSession()
    
    private init() {
    }
    
    public class func videoDevices() -> [AVCaptureDevice] {
        
        var captureDevices = [AVCaptureDevice]()
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        
        devices.forEach { (device) in
            let captureDevice = device as! AVCaptureDevice
            captureDevices.append(captureDevice)
        }
     
        return captureDevices
    }
    
    func switchDefaultDevice() throws {


        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)

        
        do {
            try self.updateCaptureSession(captureDevice!)
        } catch _ {
            throw NSError(domain: TeitenError.errorDomain!, code: -1, userInfo: ["description": "can not update CaptureSession"])
        }
    }
    
    func switchDevice(localizedName:String) throws {
        
        var captureDevice:AVCaptureDevice?
        for device in self.dynamicType.videoDevices() {
            if device.localizedName == localizedName {
                captureDevice = device
                break
            }
        }
        
        do {
            try self.updateCaptureSession(captureDevice!)
        } catch _ {
            throw NSError(domain: TeitenError.errorDomain!, code: -1, userInfo: ["description": "can not update CaptureSession"])
        }
        
    }
    
    private func updateCaptureSession(captureDevice: AVCaptureDevice) throws {
    
        self.captureSession.beginConfiguration()
        
        let videoInput:AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: captureDevice)
        } catch _ {
            throw NSError(domain: TeitenError.errorDomain!, code: -1, userInfo: ["description": "notfound AVCaptureDevice"])
        }
        
        for deviceInput in self.captureSession.inputs {
            let videoDeviceInput = deviceInput as! AVCaptureDeviceInput
            if videoDeviceInput.device.hasMediaType(AVMediaTypeVideo) {
                
                self.captureSession.removeInput(videoDeviceInput)
                if self.captureSession.canAddInput(videoInput) {
                    self.captureSession.addInput(videoInput as AVCaptureInput)
                } else {
                    throw NSError(domain: TeitenError.errorDomain!, code: -1, userInfo: ["description": "cannot add \(videoInput)"])
                }
                
                break
                
            }
            
        }
        
        self.captureSession.commitConfiguration()
    
    }
    
}