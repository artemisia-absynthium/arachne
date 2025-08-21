//
// ArachneService.swift - the Arachne Service definition
// This source file is part of the Arachne open source project
//
// Copyright (c) 2021 - 2024 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation

/// Build an `enum` that extends this `Protocol` to represent your API service.
public protocol ArachneService: Sendable {
    /// The complete base URL, example: `"https://www.myserver.io/v1"`
    var baseUrl: String { get }

    /// The path of the endpoint
    var path: String { get }

    /// Optional query string items
    var queryStringItems: [URLQueryItem]? { get }

    /// The HTTP method of the endpoint
    var method: HttpMethod { get }

    /// Optional request body encoded data
    var body: Data? { get }

    /// Optional request headers
    var headers: [String: String]? { get }

    /// HTTP response status codes that you consider valid, default value is [200...299].
    var validCodes: [Int] { get }

    /// HTTP response expected mime type, default value is `nil`.
    var expectedMimeType: String? { get }

    /// Timeout interval, default value is `nil`, which leaves default value of `URLRequest`: 60 seconds.
    var timeoutInterval: Double? { get }
}

public extension ArachneService {
    var validCodes: [Int] {
        Array(200...299)
    }

    var expectedMimeType: String? {
        nil
    }

    var timeoutInterval: Double? {
        nil
    }

    /// Utility method to get the full `URL` for a target
    /// - Throws: `URLError` if any of the `URL` components are invalid.
    internal func url() throws -> URL {
        return try composedUrl(for: self)
    }

    /// Utility method to get the `URLRequest` for a target
    /// - Throws: `URLError` if any of the `URL` components are invalid.
    /// > Tip: The output request is not modified using the `requestModifier` you set using
    /// ``ArachneProvider/with(requestModifier:)``, you may want to use ``ArachneProvider/urlRequest(for:)``.
    internal func urlRequest() throws -> URLRequest {
        return composedRequest(for: self, url: try url(), timeoutInterval: timeoutInterval)
    }
}
