//
//  AppDelegate.swift
//  RPFX
//
//  Created by Vincent Liu on 17/4/20.
//  Copyright © 2020 Vincent Liu. All rights reserved.
//

import Cocoa
import SwiftUI

import SwordRPC


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

//    var window: NSWindow!
    var timer: Timer?
    var rpc: SwordRPC?
    var startDate: Date?

    func beginTimer() {
        timer = Timer(timeInterval: TimeInterval(refreshInterval), repeats: true, block: { _ in
            self.updateStatus()
        })
        RunLoop.main.add(timer!, forMode: .common)
        timer!.fire()
    }

    func clearTimer() {
        timer?.invalidate()
    }

    func updateStatus() {
        var p = RichPresence()

        let fn = getActiveFilename()
        let ws = getActiveWorkspace()

        // determine file type
        if fn != nil {
            p.details = "Editing \(fn!)"

            if let fileExt = getFileExt(fn!), discordRPImageKeys.contains(fileExt) {
                p.assets.largeImage = fileExt
            } else {
                p.assets.largeImage = discordRPImageKeyDefault
            }
        }

        // determine workspace type
        if ws != nil {
            if ws != "Untitled" {
                p.state = "in \(withoutFileExt(ws!))"
            }
        }

        // Xcode was just launched?
        if fn == nil && ws == nil {
            p.assets.largeImage = discordRPImageKeyXcode
            p.details = "No file open"
        }

        p.timestamps.start = startDate!
        p.timestamps.end = nil
        rpc!.setPresence(p)
//        print("updating RP")
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("app launched")
        // init discord stuff
        rpc = SwordRPC.init(appId: discordClientId)
        rpc!.delegate = self

        for app in NSWorkspace.shared.runningApplications {
            // check if xcode is running
            if app.bundleIdentifier == xcodeBundleId {
//                print("xcode running, connecting...")
                rpc!.connect()
            }
        }

        let notifCenter = NSWorkspace.shared.notificationCenter

        // run on Xcode launch
        notifCenter.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: nil, using: { notif in
            if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                if app.bundleIdentifier == xcodeBundleId {
//                    print("xcode launched, connecting...")
                    self.rpc!.connect()
                }
            }
        })

        // run on Xcode close
        notifCenter.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: nil, using: { notif in
            if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                if app.bundleIdentifier == xcodeBundleId {
//                    print("xcode closed, disconnecting...")
                    self.rpc!.disconnect()
                }
            }
        })


    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        clearTimer()
    }


}

extension AppDelegate: SwordRPCDelegate {
    func swordRPCDidConnect(_ rpc: SwordRPC) {
//        print("connected")
        startDate = Date()
        beginTimer()
    }

    func swordRPCDidDisconnect(_ rpc: SwordRPC, code: Int?, message msg: String?) {
//        print("disconnected")
        clearTimer()
    }

    func swordRPCDidReceiveError(_ rpc: SwordRPC, code: Int, message msg: String) {
    
    }
}
