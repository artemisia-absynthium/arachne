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
public struct ArachneProvider<T: ArachneService> {
    private let urlSession: URLSession
    private let requestModifier: ((T, inout URLRequest) async throws -> Void)?
    private let plugins: [ArachnePlugin]?

    /// Initialize a provider that uses an asynchronous function to modify requests.
    /// - Parameters:
    ///   - urlSession: Your `URLSession`.
    ///   - requestModifier: An optional async throwing function that allows to modify the `URLRequest`, based on the given `T` endpoint, before it's submitted.
    ///   - plugins: An optional array of ``ArachnePlugin``s.
    private init(urlSession: URLSession, requestModifier: ((T, inout URLRequest) async throws -> Void)?, plugins: [ArachnePlugin]?) {
        self.urlSession = urlSession
        self.requestModifier = requestModifier
        self.plugins = plugins
    }

    /// Initialize a provider with a given `URLSession`, no plugins and no request modifier.
    /// It can be used as a starting point to set plugins and request modifier with chained calls to ``with(plugins:)`` and ``with(requestModifier:)``.
    /// - Parameter urlSession: Your `URLSession`. It uses the shared instance if none is passed.
    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        self.plugins = nil
        self.requestModifier = nil
    }

    /// Adds the given `plugins` to ``ArachneProvider``.
    /// - Parameter plugins: An array of ``ArachnePlugin``s to be added to the provider.
    /// - Returns: The same ``ArachneProvider`` with the added `plugins`.
    public func with(plugins: [ArachnePlugin]) -> ArachneProvider<T> {
        return ArachneProvider(urlSession: urlSession, requestModifier: requestModifier, plugins: plugins)
    }

    /// Adds the given `requestModifier` to ``ArachneProvider``.
    ///
    /// Example:
    /// ```
    /// let requestModifier: (T, inout URLRequest) async throws -> Void = { endpoint, request in
    ///     switch endpoint {
    ///     case .authEndpoint:
    ///         request.addValue("Bearer Token", forHTTPHeaderField: "Authorization")
    ///     default:
    ///         break
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter requestModifier: An optional async throwing function that allows to modify the `URLRequest`, based on the given `T` endpoint, before it's submitted.
    /// - Returns: The same ``ArachneProvider`` with the given `requestModifier`.
    public func with(requestModifier: @escaping (T, inout URLRequest) async throws -> Void) -> ArachneProvider<T> {
        return ArachneProvider(urlSession: urlSession, requestModifier: requestModifier, plugins: plugins)
    }

    // MARK: - Tasks

    /// Make a request to an endpoint defined in an ``ArachneService``.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - timeoutInterval: Optional timeout interval in seconds.
    ///   Default value is the default of `URLRequest`: 60 seconds.
    ///   - session: Optionally pass any session you want to use instead of the one of the provider.
    /// - Returns: The data retrieved from the endpoint, along with the response.
    /// - Throws: The `URLError` thrown in your `signingFunction` or `signingPublisher`,
    /// ``ARError/unacceptableStatusCode(statusCode:response:responseContent:)``
    /// if the response code doesn't fall in your ``ArachneService/validCodes-85b1u``.
    public func data(_ target: T,
                     timeoutInterval: Double? = nil,
                     session: URLSession? = nil) async throws -> (Data, URLResponse) {
        let request = try await buildCompleteRequest(target: target, timeoutInterval: timeoutInterval)
        self.plugins?.forEach { $0.handle(request: request) }
        let currentSession = session ?? self.urlSession
        if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            do {
                let (data, response) = try await currentSession.data(for: request)
                return try handleDataResponse(target: target, data: data, response: response)
            } catch {
                throw handleAndReturn(error: error, request: request)
            }
        } else {
            return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Data, URLResponse), Error>) in
                currentSession.dataTask(with: request) { data, response, error in
                    guard let data = data, let response = response, error == nil else {
                        return continuation.resume(throwing: self.handleAndReturn(error: error!, request: request))
                    }
                    do {
                        let (data, response) = try self.handleDataResponse(target: target, data: data, response: response)
                        continuation.resume(returning: (data, response))
                    } catch {
                        continuation.resume(throwing: self.handleAndReturn(error: error, request: request))
                    }
                }.resume()
            }
        }
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
    /// ``ARError/unacceptableStatusCode(statusCode:response:responseContent:)``
    ///  if the response code doesn't fall in your ``ArachneService/validCodes-85b1u``.
    public func download(_ target: T,
                         timeoutInterval: Double? = nil,
                         session: URLSession? = nil) async throws -> (URL, URLResponse) {
        let request = try await buildCompleteRequest(target: target, timeoutInterval: timeoutInterval)
        self.plugins?.forEach { $0.handle(request: request) }
        let currentSession = session ?? self.urlSession
        if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            do {
                let (url, response) = try await currentSession.download(for: request)
                return try handleDownloadResponse(target: target, url: url, response: response)
            } catch {
                throw handleAndReturn(error: error, request: request)
            }
        } else {
            return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(URL, URLResponse), Error>) in
                currentSession.downloadTask(with: request) { url, response, error in
                    guard let url = url, let response = response, error == nil else {
                        return continuation.resume(throwing: self.handleAndReturn(error: error!, request: request))
                    }
                    do {
                        let (url, response) = try self.handleDownloadResponse(target: target, url: url, response: response)
                        continuation.resume(returning: (url, response))
                    } catch {
                        continuation.resume(throwing: self.handleAndReturn(error: error, request: request))
                    }
                }.resume()
            }
        }
    }

    // MARK: - URLRequest

    /// Builds a `URLRequest` from an ``ArachneService`` endpoint definition.
    ///
    /// The output request is not modified using the provided `signingFunction` or `requestModifier`, you may want to use ``buildCompleteRequest(target:timeoutInterval:)``.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - timeoutInterval: Optional timeout interval in seconds.
    ///   Default value is the default of `URLRequest`: 60 seconds.
    /// - Returns: The built `URLRequest`.
    public func buildRequest(target: T, timeoutInterval: Double? = nil) throws -> URLRequest {
        let url = try URLUtil.composedUrl(for: target)
        return URLUtil.composedRequest(for: target, url: url, timeoutInterval: timeoutInterval)
    }

    /// Builds a `URLRequest` from an ``ArachneService`` endpoint definition, modified using the provided `signingFunction` or `requestModifier`, if any.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - timeoutInterval: Optional timeout interval in seconds.
    ///   Default value is the default of `URLRequest`: 60 seconds.
    /// - Returns: The built `URLRequest`.
    public func buildCompleteRequest(target: T, timeoutInterval: Double? = nil) async throws -> URLRequest {
        let url = try URLUtil.composedUrl(for: target)
        var request = URLUtil.composedRequest(for: target, url: url, timeoutInterval: timeoutInterval)
        try await modify(request: &request, target: target)
        return request
    }

    // MARK: - Internal methods

    private func modify(request: inout URLRequest, target: T) async throws {
        if let requestModifier = requestModifier {
            try await requestModifier(target, &request)
        }
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
