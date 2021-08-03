//
//  HelperFunctions.swift
//  RPFX
//
//  Created by Vincent Liu on 18/4/20.
//  Copyright © 2020 Vincent Liu. All rights reserved.
//

import Foundation

func debugPrint(_ msg: String) {
    if debug {
        print("[RPFX] " + msg)
    }
}

func getFileExt(_ file: String) -> String? {
    if let ext = file.split(separator: ".").last {
        return String(ext)
    }
    return nil
}

func withoutFileExt(_ file: String) -> String {
    if !file.contains(".") || file.last == "." {
        return file
    }

    var ret = file
    while (ret.popLast() != ".") {}
    return ret
}
