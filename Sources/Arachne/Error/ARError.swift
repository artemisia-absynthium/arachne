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

    /// Error thrown if the response mime type does not match the expected one
    ///
    /// The fields returned in the error are:
    ///  - mimeType: The response mime type
    ///  - response: The response returned from the server
    ///  - responseContent: The response content, the response type can be
    ///    - `Data`, containing the response body, in case you used
    ///    ``ArachneProvider/data(_:timeoutInterval:session:)``
    ///    - `URL`, the temporary downloaded file URL,
    ///    in case you used ``ArachneProvider/download(_:timeoutInterval:session:)``
    case unexpectedMimeType(mimeType: String?, response: HTTPURLResponse, responseContent: Any)

    /// Error thrown if a download task returns with no error but either one of URL or URLResponse is nil.
    ///
    /// It should never happen, it's been defined to ensure code correctness.
    ///
    /// The fields returned in the error are:
    ///  - url: The oprional downloaded file URL
    ///  - urlResponse: The optional response returned from the server
    case missingData(URL?, URLResponse?)
}

public extension ARError {
    /// The optional underlying error that caused `ARError` to be thrown
    internal var underlyingError: Error? {
        switch self {
        case .unacceptableStatusCode, .unexpectedMimeType, .missingData:
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
        case .unexpectedMimeType(let mimeType, _, _):
            return "Unexpected mime type: \(String(describing: mimeType))"
        case .missingData(let url, let response):
            return "Either one of URL or URLResponse are missing: URL=\(String(describing: url)), URLResponse=\(String(describing: response))"
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
        case .unexpectedMimeType:
            return 902
        case .missingData:
            return 903
        }
    }
}
