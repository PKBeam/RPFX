//
//  Constants.swift
//  RPFX
//
//  Created by Vincent Liu on 18/4/20.
//  Copyright © 2020 Vincent Liu. All rights reserved.
//

import Foundation


// used to register for notifs when Xcode opens/closes
let xcodeBundleId = "com.apple.mail"

// how often we check Xcode for a status update
let refreshInterval = 5 // seconds

// some other window names of Xcode
// Can we tell if the user is browsing Developer Docs?

//let xcodeWindowNames = [
//    "Devices", // Devices and Simulators
//    "Organiser", // Organiser
//    "Choose Package Repository:",
//    "Choose Package Options:",
//    "Window"
//    // prefix "Add Package to "
//]

// The following constants are for use with the Discord App
// if you're using your own Discord App, update this as needed

let discordClientId = "700358131481444403"

// discord image keys of supported file types
let discordRPImageKeys = [
    "swift",
    "playground",
    "storyboard",
    "xcodeproj",
    "h",
    "m",
    "cpp",
    "c",
]

// fallback for unsupported file types
let discordRPImageKeyDefault = "file"

// Xcode application icon
let discordRPImageKeyXcode = "xcode"

