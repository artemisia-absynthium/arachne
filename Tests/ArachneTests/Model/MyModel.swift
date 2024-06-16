//
// MyModel.swift - test suite model
// This source file is part of the Arachne open source project
//
// Copyright (c) 2021 - 2024 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation

struct MyModel: Decodable, Equatable {
    let field: String

    static func == (lhs: MyModel, rhs: MyModel) -> Bool {
        lhs.field == rhs.field
    }
}
