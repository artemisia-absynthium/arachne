//
// StubURLProtocol.swift - Stub URL protocol that responds to requests locally
// This source file is part of the Arachne open source project
//
// Copyright (c) 2023 - 2024 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation

/// Inspired by https://www.theinkedengineer.com/articles/mocking-requests-using-url-protocol
class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var stubExchanges: Set<StubNetworkExchange> = []
    private var isCancelled = false

    override class func canInit(with task: URLSessionTask) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        defer {
            client?.urlProtocolDidFinishLoading(self)
        }

        guard let foundExchange = Self.stubExchanges.first(where: {
            $0.urlRequest.url == request.url &&
            $0.urlRequest.url?.path == request.url?.path &&
            $0.urlRequest.httpMethod == request.httpMethod &&
            $0.urlRequest.url?.query == request.url?.query
        }) else {
            client?.urlProtocol(self, didFailWithError: URLError(.resourceUnavailable, userInfo: [:]))
            return
        }

        client?.urlProtocol(self, didReceive: foundExchange.urlResponse, cacheStoragePolicy: .notAllowed)

        if let data = foundExchange.response.data {
            sendDataInChunks(data: data)
        }
    }

    override func stopLoading() {
        isCancelled = true
    }
    
    private func sendDataInChunks(data: Data) {
        let chunkSize = 1024 * 30 // 30KB chunks
        var offset = 0
        
        while offset < data.count && !isCancelled {
            let chunk = data.subdata(in: offset..<min(offset + chunkSize, data.count))
            client?.urlProtocol(self, didLoad: chunk)
            offset += chunkSize
            Thread.sleep(forTimeInterval: 0.1) // Simulate network delay
        }
        
        if !isCancelled {
            client?.urlProtocolDidFinishLoading(self)
        }
    }
}

struct StubResponse {
    /// Response HTTP status code
    let statusCode: Int

    /// Response body
    let data: Data?

    /// Response headers
    let headers: [String: String]?
}

struct StubNetworkExchange: Hashable {
    static func == (lhs: StubNetworkExchange, rhs: StubNetworkExchange) -> Bool {
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

    /// The stub response of the exchange.
    let response: StubResponse

    /// The expected `HTTPURLResponse` built from the `StubResponse`.
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
