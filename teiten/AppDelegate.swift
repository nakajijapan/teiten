//
//  AppDelegate.swift
//  teiten
//
//  Created by nakajijapan on 12/21/14.
//  Copyright (c) 2014 net.nakajijapan. All rights reserved.
//

import Cocoa
import AVFoundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, FileDeletable {
    
    @IBOutlet weak var cameraMenu: NSMenu!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        self.addCameraItemsInMenuItem()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.handleCaptureDeviceWasConnected(_:)), name: AVCaptureDeviceWasConnectedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.handleCaptureDeviceWasDisconnected(_:)), name: AVCaptureDeviceWasDisconnectedNotification, object: nil)
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    // kill process when application closed window
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - Notifications

    func handleCaptureDeviceWasConnected(notification:NSNotification) {
        self.addCameraItemsInMenuItem()
    }
    
    func handleCaptureDeviceWasDisconnected(notification:NSNotification) {
        self.addCameraItemsInMenuItem()
        
        do {
            try VideoDeviceManager.sharedManager.switchDefaultDevice()
        } catch _ {
            print("no device")
        }
    }
    
    
    // MARK: - Actions
    
    func addCameraItemsInMenuItem() {
        
        self.cameraMenu.removeAllItems()
        VideoDeviceManager.videoDevices().forEach { (device) in
            let menuItem = NSMenuItem(title: device.localizedName, action: #selector(AppDelegate.menuItemDidClick(_:)), keyEquivalent: "")
            self.cameraMenu.addItem(menuItem)
        }
        
    }
    
    func menuItemDidClick(menuItem: NSMenuItem) {
        do {
            try VideoDeviceManager.sharedManager.switchDevice(menuItem.title)
        } catch _ {
            print("no device")
        }
    }
    
    @IBAction func captureImageMenuItemDidSelect(sender: AnyObject) {
        
        guard let mainWindow = NSApplication.sharedApplication().mainWindow else {
            return
        }
        
        guard let captureViewController = mainWindow.contentViewController as? CaptureViewController else {
            return
        }

        captureViewController.captureImage()
    }
    
    
    @IBAction func createMovieMenuItemDidSelect(sender: AnyObject) {
        
        guard let mainWindow = NSApplication.sharedApplication().mainWindow else {
            return
        }
        
        guard let captureViewController = mainWindow.contentViewController as? CaptureViewController else {
            return
        }
        
        captureViewController.createMovie()

    }
    
    @IBAction func clearCacheMenuItemDidSelect(sender: AnyObject) {

        let paths = [
            "\(kAppHomePath)/images",
            "\(kAppHomePath)/videos"
        ]
        
        self.removeFilesByDirecotries(paths: paths)

        // Alert
        let alert = NSAlert()
        alert.alertStyle = NSAlertStyle.InformationalAlertStyle
        alert.messageText = "Complete!!"
        alert.informativeText = "finished clearing cache"
        alert.runModal()
        
    }
    
}
