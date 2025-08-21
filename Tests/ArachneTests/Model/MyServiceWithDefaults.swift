//
// MyServiceWithDefaults.swift - test suite service definition
// This source file is part of the Arachne open source project
//
// Copyright (c) 2023 - 2025 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation
import Arachne

enum MyServiceWithDefaults: CaseIterable {
    case postSomething
    case notFound
    case nilUrl
    case reservedHeader
}

extension MyServiceWithDefaults: ArachneService {
    var baseUrl: String {
        "https://api.myservice.com"
    }

    var path: String {
        switch self {
        case .postSomething:
            "/postSomething"
        case .notFound:
            "/notFound"
        case .nilUrl:
            "malformedQueryStringItems"
        case .reservedHeader:
            "/reservedHeader"
        }
    }

    var queryStringItems: [URLQueryItem]? {
        switch self {
        case .nilUrl, .reservedHeader:
            [
                URLQueryItem(name: "key", value: "value")
            ]
        default:
            nil
        }
    }

    var method: Arachne.HttpMethod {
        switch self {
        case .postSomething:
            .post
        default:
            .get
        }
    }

    var body: Data? {
        switch self {
        case .postSomething:
            "I'm posting something".data(using: .utf8)
        default:
            nil
        }
    }

    var headers: [String : String]? {
        switch self {
        case .reservedHeader:
            ["Content-Length": "1234"]
        default:
            nil
        }
    }

    var stubResponse: StubResponse {
        switch self {
        case .postSomething:
            StubResponse(statusCode: 200, data: nil, headers: nil)
        case .notFound:
            StubResponse(statusCode: 404, data: nil, headers: nil)
        case .nilUrl, .reservedHeader:
            StubResponse(statusCode: 400, data: nil, headers: nil)
        }
    }
}
