//
// AROutput.swift - Output wrapper with output type cases
// This source file is part of the Arachne open source project
//
// Copyright (c) 2021 - 2024 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation

/// All possible request output types, plus `other` for all output types that are not supported on all of the platform versions supported by this library.
/// For the reason behind the choice of using the `other` case see https://github.com/apple/swift/pull/36327
public enum AROutput: Sendable {
    case data(Data)
    case url(URL)
    
    /// `Any` is `URLSession.AsyncBytes` on macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0 and later.
    /// It's not used on earlier platforms.
    case other(any Sendable)
}
