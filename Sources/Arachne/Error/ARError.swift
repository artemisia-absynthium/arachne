//
// ARError.swift - all the possible errors thrown by Arachne
// This source file is part of the Arachne open source project
//
// Copyright (c) 2021 - 2025 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation

/// Errors that can be thrown by Arachne networking library
public enum ARError: Error {
    /// Error thrown if the response status code is not acceptable
    /// based on the definition given in your ``ArachneService``.
    ///
    /// - Parameters:
    ///  - statusCode: The optional HTTP status code returned
    ///  - response: The optional response returned from the server
    ///  - responseContent: The response content, conveniently wrapped in an enum with the possible data types
    case unacceptableStatusCode(statusCode: Int?, response: HTTPURLResponse?, responseContent: AROutput)

    /// Error thrown if the response mime type does not match the expected one.
    ///
    /// - Parameters:
    ///  - mimeType: The response mime type
    ///  - response: The response returned from the server
    ///  - responseContent: The response content, conveniently wrapped in an enum with the possible data types
    case unexpectedMimeType(mimeType: String?, response: HTTPURLResponse, responseContent: AROutput)

    /// Error thrown if a download task returns with no error but either one of URL or URLResponse is `nil`.
    ///
    /// It should never happen, it's been defined to ensure code correctness.
    ///
    /// - Parameters:
    ///  - url: The oprional downloaded file URL
    ///  - urlResponse:  The optional response returned from the server
    case missingData(URL?, URLResponse?)
}

public extension ARError {
    /// The optional underlying error that caused `ARError` to be thrown
    internal var underlyingError: Error? {
        switch self {
        case .unacceptableStatusCode, .unexpectedMimeType, .missingData:
            nil
        }
    }
}

// MARK: - Localized descriptions

extension ARError: LocalizedError {
    /// A string containing the description of the error
    public var errorDescription: String? {
        switch self {
        case .unacceptableStatusCode(let code, _, _):
            "Unacceptable status code: \(String(describing: code))"
        case .unexpectedMimeType(let mimeType, _, _):
            "Unexpected mime type: \(String(describing: mimeType))"
        case .missingData(let url, let response):
            """
            URL and/or URLResponse are missing:
            URL=\(String(describing: url))
            URLResponse=\(String(describing: response))
            """
        }
    }
}

// MARK: - Compatibility with NSError

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
            901
        case .unexpectedMimeType:
            902
        case .missingData:
            903
        }
    }
}

// MARK: - Download resume data

public extension Error {
    /// Returns data useful to resume a failed download, if any
    var downloadResumeData: Data? {
        (self as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data
    }
}
