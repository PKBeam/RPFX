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
        statusUpdateTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(refreshInterval), repeats: true, block: { _ in
            self.updateStatus()
//            print("presence updating")
        })
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
//        print("updating RP")
    }

    func initRPC() {
        // init discord stuff
        rpc = SwordRPC.init(appId: discordClientId)
        rpc!.delegate = self
        // the API doesnt seem to like it if we try to connect too often?
        discordConnectTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { timer in
            if self.rpc!.connect() {
//                print("connected")
                timer.invalidate()
            }
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
            self.discordConnectTimer!.fire()
        })
    }

    func deinitRPC() {
        self.rpc!.setPresence(RichPresence())
//        self.rpc!.disconnect()
        discordConnectTimer?.invalidate()
        self.rpc = nil
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
//        print("app launched")
        let openApps = NSWorkspace.shared.runningApplications
        var xcodeOpen = openApps.filter({$0.bundleIdentifier == xcodeBundleId}).count > 0
        var discordOpen = openApps.filter({$0.bundleIdentifier == discordBundleId}).count > 0

        if xcodeOpen && discordOpen {
            initRPC()
        }

        let notifCenter = NSWorkspace.shared.notificationCenter

        // run on Discord/Xcode launch
        notifCenter.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: nil, using: { notif in
            if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                let appName = app.bundleIdentifier
                if appName == xcodeBundleId {
                    xcodeOpen = true
                }
                if appName == discordBundleId {
                    discordOpen = true
                }
                if xcodeOpen && discordOpen {
                    self.initRPC()
                }
            }
        })

        // run on Discord/Xcode close
        notifCenter.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: nil, using: { notif in
            if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                let appName = app.bundleIdentifier
                if appName == xcodeBundleId {
                    xcodeOpen = false
                    self.deinitRPC()
                }
                if appName == discordBundleId {
                    discordOpen = false
                    self.deinitRPC()
                }
            }
        })


    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
//        print("app closing")
        deinitRPC()
        statusUpdateTimer?.invalidate()
        discordConnectTimer?.invalidate()
    }


}

extension AppDelegate: SwordRPCDelegate {
    func swordRPCDidConnect(_ rpc: SwordRPC) {
//        print("SwordRPC connected")
        startDate = Date()
        beginTimer()
    }

    func swordRPCDidDisconnect(_ rpc: SwordRPC, code: Int?, message msg: String?) {
//        print("disconnected")
        statusUpdateTimer?.invalidate()
    }

    func swordRPCDidReceiveError(_ rpc: SwordRPC, code: Int, message msg: String) {
    
    }
}

struct AppDelegate_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
