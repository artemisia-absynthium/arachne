//
// Util.swift - Test utils file
//
// Copyright (c) 2024 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation

let sampleImageUrl: URL = Bundle.module.url(forResource: "image", withExtension: "png")!

var sampleImageData: Data {
    let path: String
    if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
        path = sampleImageUrl.path()
    } else {
        path = sampleImageUrl.path
    }
    return FileManager.default.contents(atPath: path)!
}
