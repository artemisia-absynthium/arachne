//
// GithubUser.swift - test suite model
// This source file is part of the Arachne open source project
//
// Copyright (c) 2021 - 2023 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation

struct GithubUser: Codable, Equatable {
    let login: String

    static func == (lhs: GithubUser, rhs: GithubUser) -> Bool {
        return lhs.login == rhs.login
    }
}
