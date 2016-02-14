//
//  AppDelegate.swift
//  teiten
//
//  Created by nakajijapan on 12/21/14.
//  Copyright (c) 2014 net.nakajijapan. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    // kill process when application closed window
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
    
    
    // MARK: - Actions
    
    @IBAction func didPushButtonOpenWindow(sender: NSMenuItem) {
        let url = NSURL(string: "file://\(kAppHomePath)/images")!
        NSWorkspace.sharedWorkspace().openURL(url)
    }
    @IBAction func didTapMenuButtonOpenMoviesFinder(sender: AnyObject) {
        let url = NSURL(string: "file://\(kAppHomePath)/videos")!
        NSWorkspace.sharedWorkspace().openURL(url)

    }
}
