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

    var statusUpdateTimer: Timer!
    var discordConnectTimer: Timer!
    var rpc: SwordRPC?
    var connectionStartDate: Date!    // the time the connection to Discord RPC was initialised

    func updateStatus() {
        debugPrint("updating Rich Presence status")

        var rp = RichPresence()
        let fn = getActiveFilename()
        let ws = getActiveWorkspace()

        // determine file type
        if let fileName = fn {
            rp.details = "Editing \(fileName)"

            // do we recognise this file type?
            if let fileExt = getFileExt(fileName), discordRPImageKeys.contains(fileExt) {
                rp.assets.largeImage = fileExt
            } else {
                rp.assets.largeImage = discordRPImageKeyDefault
            }
        }

        // determine workspace type
        if let workspace = ws, workspace != xcodeUntitledWorkspace {
            rp.state = "in \(withoutFileExt(workspace))"
        }

        // Xcode was just launched?
        if fn == nil && ws == nil {
            rp.assets.largeImage = discordRPImageKeyXcode
            rp.details = "No file open"
        }

        // set timestamps
        rp.timestamps.start = connectionStartDate
        rp.timestamps.end = nil

        // finally, set rich presence
        rpc!.setPresence(rp)
    }

    func initRPC() {
        debugPrint("initialising RPC...")
        // init discord stuff
        rpc = SwordRPC.init(appId: discordClientId)
        rpc!.delegate = self

        discordConnectTimer = Timer.scheduledTimer(
            withTimeInterval: discordConnectInterval, // the API doesn't seem to like it if we try to connect too often
            repeats: true,
            block: { timer in
                debugPrint("-- trying to connect to Discord...")
                if self.rpc!.connect() {
                    timer.invalidate()
                }
            }
        )
        discordConnectTimer.fire()
    }

    func deinitRPC() {
        debugPrint("deinitialising RPC")
        discordConnectTimer.invalidate()
        statusUpdateTimer.invalidate()
        rpc!.disconnect()
        self.rpc = nil
    }

    func scanRunningApplications() {
        let runningApps = NSWorkspace.shared.runningApplications
        let xcodeOpen = runningApps.contains(where: {$0.bundleIdentifier == xcodeBundleId})
        let discordOpen = runningApps.contains(where: {$0.bundleIdentifier == discordBundleId})

        if xcodeOpen && discordOpen {
            initRPC()
        } else if rpc != nil {
            deinitRPC()
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        debugPrint("RPFX launched")
        scanRunningApplications()

        // closure that updates RPC connection status if Xcode/Discord were involved in the notification
        let onNotif: (Notification) -> Void = { notification in
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                if [xcodeBundleId, discordBundleId].contains(app.bundleIdentifier) {
                    self.scanRunningApplications()
                }
            }
        }

        let notifCenter = NSWorkspace.shared.notificationCenter
        notifCenter.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: nil, using: onNotif)
        notifCenter.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: nil, using: onNotif)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        debugPrint("RPFX shutting down...")
        if rpc != nil {
            deinitRPC()
        }
    }
}

extension AppDelegate: SwordRPCDelegate {
    func swordRPCDidConnect(_ rpc: SwordRPC) {
        debugPrint("SwordRPC connected")

        // record the time the connection was initiated
        connectionStartDate = Date()

        // create status update timer
        statusUpdateTimer = Timer.init(
            timeInterval: statusRefreshInterval,
            repeats: true,
            block: { _ in
                self.updateStatus()
            }
        )
        // for some reason, a scheduledTimer here won't refire
        // (workaround: manually add it to the common RunLoop)
        RunLoop.main.add(statusUpdateTimer, forMode: .common)
        statusUpdateTimer.fire()
    }

    func swordRPCDidDisconnect(_ rpc: SwordRPC, code: Int?, message msg: String?) {
        debugPrint("SwordRPC disconnected")
        // stop status update timer
        statusUpdateTimer.invalidate()
    }
}
