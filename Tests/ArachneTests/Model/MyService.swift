//
// MyService.swift - test suite service definition
// This source file is part of the Arachne open source project
//
// Copyright (c) 2021 - 2023 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation
import Arachne

enum MyService: CaseIterable {
    case plainText
    case jsonResponse
    case fileDownload
    case unexpectedMimeType
}

extension MyService: ArachneService {
    var baseUrl: String {
        "https://api.myservice.com"
    }

    var path: String {
        switch self {
        case .plainText, .unexpectedMimeType:
            "/plainText"
        case .jsonResponse:
            "/jsonResponse"
        case .fileDownload:
            "/fileDownload"
        }
    }

    var queryStringItems: [URLQueryItem]? {
        switch self {
        case .fileDownload, .unexpectedMimeType:
            [
                URLQueryItem(name: "key", value: "value")
            ]
        default:
            nil
        }
    }

    var method: HttpMethod {
        .get
    }

    var body: Data? {
        nil
    }

    var headers: [String: String]? {
        ["Authentication": "Bearer 1234"]
    }

    var expectedMimeType: String? {
        switch self {
        case .plainText:
            "text/plain"
        case .jsonResponse, .unexpectedMimeType:
            "application/json"
        case .fileDownload:
            "image/png"
        }
    }

    var timeoutInterval: Double? {
        switch self {
        case .jsonResponse:
            10
        default:
            nil
        }
    }

    var stubResponse: StubResponse {
        switch self {
        case .plainText, .unexpectedMimeType:
            return StubResponse(statusCode: 200, data: "The response is 42".data(using: .utf8)!, headers: ["Content-Type": "text/plain"])
        case .jsonResponse:
            return StubResponse(statusCode: 200, data: #"{"field" : "field"}"#.data(using: .utf8)!, headers: ["Content-Type": "application/json"])
        case .fileDownload:
            let imageUrl: URL = Bundle.module.url(forResource: "image", withExtension: "png")!
            let path: String
            if #available(macOS 13.0, *) {
                path = imageUrl.path()
            } else {
                path = imageUrl.path
            }
            let content = FileManager.default.contents(atPath: path)!
            return StubResponse(statusCode: 200, data: content, headers: [
                "Content-Type": "image/png"
            ])
        }
    }
}
