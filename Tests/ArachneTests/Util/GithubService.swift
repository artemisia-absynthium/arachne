//
// GithubService.swift - test suite service definition
// This source file is part of the Arachne open source project
//
// Copyright (c) 2021 - 2023 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation
import Arachne

enum Github {
    case zen
    case userProfile(String)
    case notFound
    case avatar(String)
}

extension Github: ArachneService {
    var baseUrl: String {
        switch self {
        case .avatar:
            return "https://avatars.githubusercontent.com"
        default:
            return "https://api.github.com"
        }
    }

    var path: String {
        switch self {
        case .zen:
            return "/zen"
        case .userProfile(let name):
            return "/users/\(name)"
        case .notFound:
            return "/notFound"
        case .avatar(let id):
            return "/u/\(id)"
        }
    }

    var queryStringItems: [URLQueryItem]? {
        switch self {
        case .avatar:
            return [
                URLQueryItem(name: "v", value: "4")
            ]
        default:
            return nil
        }
    }

    var method: HttpMethod {
        return .get
    }

    var body: Data? {
        return nil
    }

    var headers: [String: String]? {
        switch self {
        case .avatar:
            return nil
        default:
            return ["Accept": "application/vnd.github.v3+json"]
        }
    }
}
