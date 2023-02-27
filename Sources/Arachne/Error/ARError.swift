//
// ARError.swift - all the possible errors thrown by Arachne
// This source file is part of the Arachne open source project
//
// Copyright (c) 2021 - 2023 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation

/// Errors that can be thrown by Arachne networking library
public enum ARError: Error {
    /// Error thrown if the response status code is not acceptable
    ///
    /// The fields returned in the error are:
    ///  - statusCode: The optional HTTP status code returned
    ///  - response: The optional response returned from the server
    ///  - responseContent: The response content, the response type can be
    ///    - `Data`, containing the response body, in case you used
    ///    ``ArachneProvider/data(_:timeoutInterval:session:)``
    ///    - `URL`, the temporary downloaded file URL,
    ///    in case you used ``ArachneProvider/download(_:timeoutInterval:session:)``
    case unacceptableStatusCode(statusCode: Int?, response: HTTPURLResponse?, responseContent: Any)
}

public extension ARError {
    /// The optional underlying error that caused `ARError` to be thrown
    internal var underlyingError: Error? {
        switch self {
        case .unacceptableStatusCode:
            return nil
        }
    }
}

// MARK: - Localized descriptions

extension ARError: LocalizedError {
    /// A string containing the description of the error
    public var errorDescription: String? {
        switch self {
        case .unacceptableStatusCode(let code, _, _):
            return "Unacceptable status code: \(String(describing: code))"
        }
    }
}

extension ARError: CustomNSError {
    public var errorUserInfo: [String: Any] {
        var userInfo: [String: Any] = [:]
        userInfo[NSLocalizedDescriptionKey] = errorDescription
        userInfo[NSUnderlyingErrorKey] = underlyingError
        return userInfo
    }

    public var errorCode: Int {
        switch self {
        case .unacceptableStatusCode:
            return 901
        }
    }
}
