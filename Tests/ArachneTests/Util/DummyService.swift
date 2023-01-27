//
// DummyService.swift - test suite service definition
// This source file is part of the Arachne open source project
//
// Copyright (c) 2021 - 2023 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation
import Arachne

enum Dummy {
    case malformedUrl
    case nilUrl
    case reservedHeader
    case postSomething
}

extension Dummy: ArachneService {
    var baseUrl: String {
        switch self {
        case .malformedUrl:
            return "htp:🥶/malformedUrl"
        default:
            return "https://malformedquerystring.io"
        }
    }

    var path: String {
        switch self {
        case .malformedUrl:
            return "/malformedUrl"
        case .nilUrl:
            return "malformedQueryStringItems"
        case .reservedHeader:
            return "/reservedHeader"
        case .postSomething:
            return "/postSomething"
        }
    }

    var queryStringItems: [URLQueryItem]? {
        switch self {
        default:
            return [
                URLQueryItem(name: "key", value: "value")
            ]
        }
    }

    var method: HttpMethod {
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

    var headers: [String: String]? {
        switch self {
        case .reservedHeader:
            return ["Content-Length": "1234"]
        default:
            return nil
        }
    }
}
