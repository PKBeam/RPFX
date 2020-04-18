//
//  Applescript.swift
//  RPFX
//
//  Created by Vincent Liu on 17/4/20.
//  Copyright © 2020 Vincent Liu. All rights reserved.
//

import Foundation
import Cocoa

enum APScripts: String {
    case windowNames = "return name of windows"
    case filePaths = "return file of documents"
    case documentNames = "return name of documents"
    case activeWorkspaceDocument = "return active workspace document"
}

func runAPScript(_ s: APScripts) -> [String]? {
    let scr = """
    tell application "Xcode"
        \(s.rawValue)
    end tell
    """

    // execute the script
    let script = NSAppleScript.init(source: scr)
    let result = script?.executeAndReturnError(nil)

    // format the result as a Swift array
    if let desc = result {
        var arr: [String] = []
        for i in 1...desc.numberOfItems {
            let strVal = desc.atIndex(i)!.stringValue
            if var uwStrVal = strVal {
                // remove " — Edited" suffix if it exists
                if uwStrVal.hasSuffix(" — Edited") {
                    uwStrVal.removeSubrange(uwStrVal.lastIndex(of: "—")!...)
                    uwStrVal.removeLast()
                }
                arr.append(uwStrVal)
            }
        }
        return arr
    }
    return nil
}

func getActiveFilename() -> String? {
    guard let fileNames = runAPScript(.documentNames) else {
        return nil
    }

    guard let windowNames = runAPScript(.windowNames) else {
        return nil
    }

    // find the first window title that matches a filename
    // (the first window name is the one in focus)
    for window in windowNames {
        // make sure the focused window refers to a file
        for file in fileNames {
            if file == window {
                return file
            }
        }
    }

    return nil
}

func getActiveWorkspace() -> String? {
    if let awd = runAPScript(.activeWorkspaceDocument) {
        return awd[1]
    }
    return nil
}
