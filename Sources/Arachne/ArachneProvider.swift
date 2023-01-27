//
// ArachneProvider.swift - the provider implementation
// This source file is part of the Arachne open source project
//
// Copyright (c) 2021 - 2023 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation

/// Use ``ArachneProvider`` to make requests to a specific ``ArachneService``.
open class ArachneProvider<T: ArachneService> {
    private let urlSession: URLSession
    private let plugins: [ArachnePlugin]?
    private let signingFunction: ((T, URLRequest) async throws -> URLRequest)?

    /// Initialize a provider that uses an asynchronous function to sign requests.
    /// - Parameters:
    ///   - urlSession: Your `URLSession`, uses default if none is passed.
    ///   - plugins: An optional array of ``ArachnePlugin``s.
    ///   - signingFunction: An optional async throwing function that signs the request before it is made.
    public init(urlSession: URLSession = URLSession(configuration: .default),
                signingFunction: ((T, URLRequest) async throws -> URLRequest)? = nil,
                plugins: [ArachnePlugin]? = nil) {
        self.urlSession = urlSession
        self.plugins = plugins
        self.signingFunction = signingFunction
    }

    // MARK: - Async/Await

    /// Make a request to an endpoint defined in an ``ArachneService``.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - timeoutInterval: Optional timeout interval in seconds.
    ///   Default value is the default of `URLRequest`: 60 seconds.
    ///   - session: Optionally pass any session you want to use instead of the one of the provider.
    /// - Returns: The data retrieved from the endpoint, along with the response.
    /// - Throws: The `URLError` thrown in your `signingFunction` or `signingPublisher`,
    /// ``ARError/malformedUrl(_:)`` if the URL is not considered valid or
    /// ``ARError/unacceptableStatusCode(statusCode:response:responseContent:)``
    /// if the response code doesn't fall in your ``ArachneService/validCodes-85b1u``.
    public func data(_ target: T,
                     timeoutInterval: Double? = nil,
                     session: URLSession? = nil) async throws -> (Data, URLResponse) {
        var request = try buildRequest(target: target, timeoutInterval: timeoutInterval)
        request = try await sign(request: request, target: target)
        self.plugins?.forEach { $0.handle(request: request) }
        let (data, response) = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Data, URLResponse), Error>) in
            (session ?? self.urlSession).dataTask(with: request) { data, response, error in
                guard let data = data, let response = response, error == nil else {
                    continuation.resume(throwing: self.handleAndReturn(error: error!, request: request))
                    return
                }
                do {
                    let (data, response) = try self.handleDataResponse(target: target, data: data, response: response)
                    continuation.resume(returning: (data, response))
                } catch {
                    continuation.resume(throwing: self.handleAndReturn(error: error, request: request))
                }
            }.resume()
        }
        return (data, response)
    }

    /// Download a resource from an endpoint defined in an ``ArachneService``.
    ///
    /// The downloaded file must be copied in the appropriate folder to be used, because Arachne makes no assumption
    /// on whether it must be cached or not so it just returns the same URL returned from `URLSession.downloadTask`.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - timeoutInterval: Optional timeout interval in seconds.
    ///   Default value is the default of `URLRequest`: 60 seconds.
    ///   - session: Optionally pass any session you want to use instead of the one of the provider.
    /// - Returns: The URL of the saved file, along with the response.
    /// - Throws: The `URLError` thrown in your `signingFunction` or `signingPublisher`,
    /// ``ARError/malformedUrl(_:)`` if the URL is not considered valid or
    /// ``ARError/unacceptableStatusCode(statusCode:response:responseContent:)``
    ///  if the response code doesn't fall in your ``ArachneService/validCodes-85b1u``.
    public func download(_ target: T,
                         timeoutInterval: Double? = nil,
                         session: URLSession? = nil) async throws -> (URL, URLResponse) {
        var request = try buildRequest(target: target, timeoutInterval: timeoutInterval)
        request = try await sign(request: request, target: target)
        self.plugins?.forEach { $0.handle(request: request) }
        let (url, response) = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(URL, URLResponse), Error>) in
            (session ?? self.urlSession).downloadTask(with: request) { url, response, error in
                guard let url = url, let response = response, error == nil else {
                    continuation.resume(throwing: self.handleAndReturn(error: error!, request: request))
                    return
                }
                do {
                    let (url, response) = try self.handleDownloadResponse(target: target, url: url, response: response)
                    continuation.resume(returning: (url, response))
                } catch {
                    continuation.resume(throwing: self.handleAndReturn(error: error, request: request))
                }
            }.resume()
        }
        return (url, response)
    }

    // MARK: - URLRequest

    /// Builds a `URLRequest` from an ``ArachneService`` endpoint definition.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - timeoutInterval: Optional timeout interval in seconds.
    ///   Default value is the default of `URLRequest`: 60 seconds.
    /// - Returns: The built `URLRequest`.
    public func buildRequest(target: T, timeoutInterval: Double?) throws -> URLRequest {
        let url = try URLUtil.composedUrl(for: target)
        return URLUtil.composedRequest(for: target, url: url, timeoutInterval: timeoutInterval)
    }

    // MARK: - Internal methods

    private func sign(request: URLRequest, target: T) async throws -> URLRequest {
        var signedRequest = request
        if let signingFunction = signingFunction {
            signedRequest = try await signingFunction(target, request)
        }
        return signedRequest
    }

    private func handleDataResponse(target: T, data: Data, response: URLResponse) throws -> (Data, URLResponse) {
        guard let httpResponse = response as? HTTPURLResponse,
              target.validCodes.contains(httpResponse.statusCode) else {
            throw ARError.unacceptableStatusCode(statusCode: (response as? HTTPURLResponse)?.statusCode,
                                                 response: response as? HTTPURLResponse,
                                                 responseContent: data)
        }
        self.plugins?.forEach { $0.handle(response: response, data: data) }
        return (data, response)
    }

    private func handleDataResponse(target: T, data: Data, response: URLResponse) throws -> Data {
        let (data, _) = try handleDataResponse(target: target, data: data, response: response)
        return data
    }

    private func handleDownloadResponse(target: T, url: URL, response: URLResponse) throws -> (URL, URLResponse) {
        guard let httpResponse = response as? HTTPURLResponse,
              target.validCodes.contains(httpResponse.statusCode) else {
            throw ARError.unacceptableStatusCode(statusCode: (response as? HTTPURLResponse)?.statusCode,
                                                 response: response as? HTTPURLResponse,
                                                 responseContent: url)
        }
        self.plugins?.forEach { $0.handle(response: response, data: url) }
        return (url, response)
    }

    private func handleAndReturn(error: Error, request: URLRequest) -> Error {
        let output = self.extractOutput(from: error)
        self.plugins?.forEach { $0.handle(error: error, request: request, output: output) }
        return error
    }

    private func extractOutput(from error: Error) -> Any? {
        var output: Any?
        if let error = error as? ARError, case .unacceptableStatusCode(_, _, let responseContent) = error {
            output = responseContent
        }
        return output
    }
}
