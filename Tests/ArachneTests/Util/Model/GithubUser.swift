//
//  File.swift
//  
//
//  Created by Cristina De Rito on 14/10/21.
//

import Foundation

struct GithubUser: Codable, Equatable {
    let login: String

    static func == (lhs: GithubUser, rhs: GithubUser) -> Bool {
        return lhs.login == rhs.login
    }
}
