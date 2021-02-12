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
    var statusUpdateTimer: Timer?
    var discordConnectTimer: Timer?
    var rpc: SwordRPC?
    var startDate: Date?

    func beginTimer() {
        statusUpdateTimer = Timer.init(timeInterval: refreshInterval, repeats: true, block: { _ in
            debugPrint("presence updating")
            self.updateStatus()
        })
        RunLoop.main.add(statusUpdateTimer!, forMode: .common)
        statusUpdateTimer!.fire()
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
        debugPrint("updating RP")
    }

    func initRPC() {
        debugPrint("init RPC")
        // init discord stuff
        rpc = SwordRPC.init(appId: discordClientId)
        rpc!.delegate = self
        // the API doesnt seem to like it if we try to connect too often?
        discordConnectTimer = Timer.scheduledTimer(withTimeInterval: discordRPCconnectInterval, repeats: true, block: { timer in
            debugPrint("trying RPC connect...")
            if self.rpc!.connect() {
                debugPrint("RPC connected")
                timer.invalidate()
            } else {
                debugPrint("RPC connect failed")
            }
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + discordRPCconnectInterval, execute: {
            self.discordConnectTimer!.fire()
        })
    }

    func deinitRPC() {
        debugPrint("deinit RPC")
        self.rpc!.setPresence(RichPresence())
//        self.rpc!.disconnect()
        discordConnectTimer?.invalidate()
        self.rpc = nil
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // keep track of whether discord or xcode are running
        var xcodeOpen = NSWorkspace.shared.runningApplications.filter({$0.bundleIdentifier == xcodeBundleId}).count > 0
        var discordOpen = NSWorkspace.shared.runningApplications.filter({$0.bundleIdentifier == discordBundleId}).count > 0

        // one time check on startup
        if xcodeOpen && discordOpen {
            initRPC()
        }

        // run on application launch
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: nil, using: { notif in
            if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                let appName = app.bundleIdentifier
                if appName == xcodeBundleId {
                    debugPrint("xcode open")
                    xcodeOpen = true
                }
                if appName == discordBundleId {
                    debugPrint("discord open")
                    discordOpen = true
                }

                if xcodeOpen && discordOpen {
                    self.initRPC()
                }
            }
        })

        // run on application close
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: nil, using: { notif in
            if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                let appName = app.bundleIdentifier
                if appName == xcodeBundleId {
                    debugPrint("xcode closed")
                    xcodeOpen = false
                    self.deinitRPC()
                }
                if appName == discordBundleId {
                    debugPrint("discord closed")
                    discordOpen = false
                    self.deinitRPC()
                }
            }
        })


    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        debugPrint("RPFX shutting down...")
        deinitRPC()
        statusUpdateTimer?.invalidate()
        discordConnectTimer?.invalidate()
    }


}

extension AppDelegate: SwordRPCDelegate {
    func swordRPCDidConnect(_ rpc: SwordRPC) {
        debugPrint("SwordRPC connected")
        startDate = Date()
        beginTimer()
    }

    func swordRPCDidDisconnect(_ rpc: SwordRPC, code: Int?, message msg: String?) {
        debugPrint("disconnected")
        statusUpdateTimer?.invalidate()
    }

    func swordRPCDidReceiveError(_ rpc: SwordRPC, code: Int, message msg: String) {
    
    }
}
