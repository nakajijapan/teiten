//
//  AppDelegate.swift
//  teiten
//
//  Created by nakajijapan on 12/21/14.
//  Copyright (c) 2014 net.nakajijapan. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, FileDeletable {
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    // kill process when application closed window
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    
    @IBAction func captureImageMenuItemDidSelect(sender: AnyObject) {
        
        guard let mainWindow = NSApplication.shared().mainWindow else {
            return
        }
        
        guard let captureViewController = mainWindow.contentViewController as? CaptureViewController else {
            return
        }

        captureViewController.captureImage()
    }
    
    
    @IBAction func createMovieMenuItemDidSelect(sender: AnyObject) {
        
        guard let mainWindow = NSApplication.shared().mainWindow else {
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
