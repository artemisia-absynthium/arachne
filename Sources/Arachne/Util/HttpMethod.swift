//
// HttpMethod.swift - HTTP methods enumeration
// This source file is part of the Arachne open source project
//
// Copyright (c) 2023 - 2025 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation

/// HTTP methods enumeration
public enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case head = "HEAD"
    case patch = "PATCH"
}
