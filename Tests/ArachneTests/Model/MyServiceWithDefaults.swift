//
// MyServiceWithDefaults.swift - test suite service definition
// This source file is part of the Arachne open source project
//
// Copyright (c) 2023 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation
import Arachne

enum MyServiceWithDefaults: CaseIterable {
    case postSomething
    case notFound
    case malformedUrl
    case nilUrl
    case reservedHeader
}

extension MyServiceWithDefaults: ArachneService {
    var baseUrl: String {
        switch self {
        case .malformedUrl:
            return "htp:🥶/malformedUrl"
        default:
            return "https://api.myservice.com"
        }
    }

    var path: String {
        switch self {
        case .postSomething:
            return "/postSomething"
        case .notFound:
            return "/notFound"
        case .malformedUrl:
            return "/malformedUrl"
        case .nilUrl:
            return "malformedQueryStringItems"
        case .reservedHeader:
            return "/reservedHeader"
        }
    }

    var queryStringItems: [URLQueryItem]? {
        switch self {
        case .malformedUrl, .nilUrl, .reservedHeader:
            return [
                URLQueryItem(name: "key", value: "value")
            ]
        default:
            return nil
        }
    }

    var method: Arachne.HttpMethod {
        switch self {
        case .postSomething:
            return .post
        default:
            return .get
        }
    }

    var body: Data? {
        switch self {
        case .postSomething:
            return "I'm posting something".data(using: .utf8)
        default:
            return nil
        }
    }

    var headers: [String : String]? {
        switch self {
        case .reservedHeader:
            return ["Content-Length": "1234"]
        default:
            return nil
        }
    }

    var mockResponse: MockResponse {
        switch self {
        case .postSomething:
            return MockResponse(statusCode: 200, data: nil, headers: nil)
        case .notFound:
            return MockResponse(statusCode: 404, data: nil, headers: nil)
        case .malformedUrl, .nilUrl, .reservedHeader:
            return MockResponse(statusCode: 400, data: nil, headers: nil)
        }
    }
}
