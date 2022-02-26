//
//  ARError.swift
//  
//
//  Created by Cristina De Rito on 30/09/21.
//

import Foundation

/// Errors that can be thrown by Arachne networking library
public enum ARError: Error {
    /// Error thrown if any part of the URL is malformed
    case malformedUrl(String)

    /// Error thrown if the response status code is not acceptable
    ///
    /// The fields returned in the error are:
    ///  - statusCode: The optional HTTP status code returned
    ///  - response: The optional response returned from the server
    ///  - responseContent: The response content, the response type can be
    ///    - `Data`, containing the response body, in case you used
    ///    `ArachneProvider.request(_:timeoutInterval:session:)`
    ///    - `URL`, the temporary downloaded file URL,
    ///    in case you used `ArachneProvider.download(_:timeoutInterval:session:)`
    case unacceptableStatusCode(statusCode: Int?, response: HTTPURLResponse?, responseContent: Any)
}

public extension ARError {
    /// The optional underlying error that caused `ARError` to be thrown
    internal var underlyingError: Error? {
        switch self {
        case .malformedUrl, .unacceptableStatusCode:
            return nil
        }
    }
}

// MARK: - Localized descriptions

extension ARError: LocalizedError {
    /// A string containing the description of the error
    public var errorDescription: String? {
        switch self {
        case .malformedUrl(let url):
            return "Malformed URL: \(url)"
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
        case .malformedUrl:
            return 900
        case .unacceptableStatusCode:
            return 901
        }
    }
}
