//
// AROutput.swift - Output wrapper with output type cases
// This source file is part of the Arachne open source project
//
// Copyright (c) 2021 - 2025 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation

/// All possible request output types, plus `other` for all output types
/// that are not supported on all of the platform versions supported by this library.
public enum AROutput: Sendable {
    case data(Data)
    case url(URL)
    case bytes(URLSession.AsyncBytes)
}
