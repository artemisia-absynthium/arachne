//
// MockURLProtocol.swift - Mock URL protocol that responds to requests locally
// This source file is part of the Arachne open source project
//
// Copyright (c) 2023 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation

/// Inspired by https://www.theinkedengineer.com/articles/mocking-requests-using-url-protocol
class MockURLProtocol: URLProtocol {
    static var mockExchanges: Set<MockNetworkExchange> = []

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        defer {
            client?.urlProtocolDidFinishLoading(self)
        }

        guard let foundExchange = Self.mockExchanges.first(where: {
            $0.urlRequest.url == request.url &&
            $0.urlRequest.url?.path == request.url?.path &&
            $0.urlRequest.httpMethod == request.httpMethod &&
            $0.urlRequest.url?.query == request.url?.query
        }) else {
            client?.urlProtocol(self, didFailWithError: URLError(.resourceUnavailable, userInfo: [:]))
            return
        }

        if let data = foundExchange.response.data {
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocol(self, didReceive: foundExchange.urlResponse, cacheStoragePolicy: .notAllowed)
    }

    override func stopLoading() {}
}

struct MockResponse {
    /// Response HTTP status code
    let statusCode: Int

    /// Response body
    let data: Data?

    /// Response headers
    let headers: [String: String]?
}

struct MockNetworkExchange: Hashable {
    static func == (lhs: MockNetworkExchange, rhs: MockNetworkExchange) -> Bool {
        lhs.urlRequest.url == rhs.urlRequest.url &&
        lhs.urlRequest.url?.path == rhs.urlRequest.url?.path &&
        lhs.urlRequest.httpMethod == rhs.urlRequest.httpMethod &&
        lhs.urlRequest.url?.query == rhs.urlRequest.url?.query
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(urlRequest.url)
        hasher.combine(urlRequest.url?.path)
        hasher.combine(urlRequest.httpMethod)
        hasher.combine(urlRequest.url?.query)
    }

    /// The `URLRequest` associated to this exchange.
    let urlRequest: URLRequest

    /// The mock response of the exchange.
    let response: MockResponse

    /// The expected `HTTPURLResponse` built from the `MockResponse`.
    var urlResponse: HTTPURLResponse {
        HTTPURLResponse(
            url: urlRequest.url!,
            statusCode: response.statusCode,
            httpVersion: "HTTP/3",
            // Merges existing headers, if any, with the custom mock headers favoring the latter.
            headerFields: (urlRequest.allHTTPHeaderFields ?? [:]).merging(response.headers ?? [:]) { $1 }
        )!
    }
}
