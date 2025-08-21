//
// ArachneProvider.swift - the provider implementation
// This source file is part of the Arachne open source project
//
// Copyright (c) 2021 - 2024 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation

/// Use ``ArachneProvider`` to make requests to a specific ``ArachneService``.
public struct ArachneProvider<T>: Sendable where T: ArachneService {
    let urlSession: URLSession
    let requestModifier: (@Sendable (T, inout URLRequest) async throws -> Void)?
    let plugins: [ArachnePlugin]?

    /// Initialize a provider that uses an asynchronous function to modify requests.
    /// - Parameters:
    ///   - urlSession: Your `URLSession`.
    ///   - requestModifier: An optional async throwing function that allows to modify the `URLRequest`,
    ///   based on the given `T` endpoint, before it's submitted.
    ///   - plugins: An optional array of ``ArachnePlugin``s.
    private init(urlSession: URLSession,
                 requestModifier: (@Sendable (T, inout URLRequest) async throws -> Void)?,
                 plugins: [ArachnePlugin]?) {
        self.urlSession = urlSession
        self.requestModifier = requestModifier
        self.plugins = plugins
    }

    /// Initialize a provider with a given `URLSession`,
    /// no plugins and no request modifier.
    /// After initializing an ``ArachneProvider`` you can add plugins and a request modifier to it
    /// by chaining calls to ``with(plugins:)`` and ``with(requestModifier:)``.
    /// - Parameter urlSession: Your `URLSession`. It uses the `shared` instance if none is passed.
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
    /// - Parameter requestModifier: An optional async throwing function that allows to modify the `URLRequest`,
    /// based on the given `T` endpoint, before it's submitted.
    /// - Returns: The same ``ArachneProvider`` with the given `requestModifier`.
    public func with(
        requestModifier: @escaping @Sendable (T, inout URLRequest) async throws -> Void
    ) -> ArachneProvider<T> {
        return ArachneProvider(urlSession: urlSession, requestModifier: requestModifier, plugins: plugins)
    }

    // MARK: - Tasks

    // MARK: Bytes

    /// Retrieves the contents from an endpoint and delivers an asynchronous sequence of bytes.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - session: Optionally pass any session you want to use instead of the one of the provider.
    /// - Returns: An asynchronously-delivered tuple that contains a `URLSession.AsyncBytes`
    /// sequence to iterate over, and a `URLResponse`.
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    public nonisolated func bytes(_ target: T,
                                  session: URLSession? = nil) async throws -> (URLSession.AsyncBytes, URLResponse) {
        let request = try await urlRequest(for: target)
        self.plugins?.forEach { $0.handle(request: request) }
        let currentSession = session ?? self.urlSession
        do {
            let (bytes, response) = try await currentSession.bytes(for: request)
            return try handleResponse(target: target, data: bytes, output: .other(bytes), response: response)
        } catch {
            throw handleAndReturn(error: error, request: request)
        }
    }

    // MARK: Data

    /// Make a request to an endpoint defined in an ``ArachneService``.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - timeoutInterval: Optional timeout interval in seconds.
    ///   Default value is the default of `URLRequest`: 60 seconds.
    ///   - session: Optionally pass any session you want to use instead of the one of the provider.
    /// - Returns: The data retrieved from the endpoint, along with the response.
    /// - Throws: `URLError` if any of the request components are invalid
    /// or the error thrown from the `requestModifier` you set using ``with(requestModifier:)``.
    ///   ``ARError/unacceptableStatusCode(statusCode:response:responseContent:)``
    ///   if the response code doesn't fall in your ``ArachneService/validCodes-85b1u``.
    ///   ``ARError/unexpectedMimeType(mimeType:response:responseContent:)``
    ///   if the response mime type doesn't match ``ArachneService/expectedMimeType-4w7gr``.
    @available(
        *,
         deprecated,
         renamed: "data(target:session:)",
         // swiftlint:disable line_length
         message: "Use data(target:session:) instead, timeoutInterval is now defined in ArachneService and the value passed as input to this method is ignored")
    // swiftlint:enable line_length
    public nonisolated func data(_ target: T,
                                 timeoutInterval: Double? = nil,
                                 session: URLSession? = nil) async throws -> (Data, URLResponse) {
        return try await data(target, session: session)
    }

    /// Make a request to an endpoint defined in an ``ArachneService``.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - session: Optionally pass any session you want to use instead of the one of the provider.
    /// - Returns: The data retrieved from the endpoint, along with the response.
    /// - Throws: `URLError` if any of the request components are invalid
    /// or the error thrown from the `requestModifier` you set using ``with(requestModifier:)``.
    ///   ``ARError/unacceptableStatusCode(statusCode:response:responseContent:)``
    ///   if the response code doesn't fall in your ``ArachneService/validCodes-85b1u``.
    ///   ``ARError/unexpectedMimeType(mimeType:response:responseContent:)``
    ///   if the response mime type doesn't match ``ArachneService/expectedMimeType-4w7gr``.
    public nonisolated func data(_ target: T, session: URLSession? = nil) async throws -> (Data, URLResponse) {
        let request = try await urlRequest(for: target)
        self.plugins?.forEach { $0.handle(request: request) }
        let currentSession = session ?? self.urlSession
        if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            do {
                let (data, response) = try await currentSession.data(for: request)
                return try handleResponse(target: target, data: data, output: .data(data), response: response)
            } catch {
                throw handleAndReturn(error: error, request: request)
            }
        } else {
            do {
                // swiftlint:disable line_length
                let (data, response) = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Data, URLResponse), Error>) in
                    // swiftlint:enable line_length
                    currentSession.dataTask(with: request) { data, response, error in
                        guard let data = data, let response = response, error == nil else {
                            return continuation.resume(throwing: error!)
                        }
                        continuation.resume(returning: (data, response))
                    }.resume()
                }
                return try handleResponse(target: target, data: data, output: .data(data), response: response)
            } catch {
                throw handleAndReturn(error: error, request: request)
            }
        }
    }

    // MARK: - URLRequest

    /// Builds a `URLRequest` from an ``ArachneService`` endpoint definition.
    ///
    /// The output request is not modified using the `requestModifier` you set
    /// using ``with(requestModifier:)``, you may want to use ``urlRequest(for:)``.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - timeoutInterval: Optional timeout interval in seconds.
    ///   Default value is the default of `URLRequest`: 60 seconds.
    /// - Returns: The built `URLRequest`.
    /// - Throws: `URLError` if any of the request components are invalid.
    @available(
        *,
         deprecated,
         // swiftlint:disable line_length
         message: "Use ArachneService.urlRequest() instead, timeoutInterval is now defined in ArachneService and the value passed as input to this method is ignored")
    // swiftlint:enable line_length
    public nonisolated func buildRequest(target: T, timeoutInterval: Double? = nil) throws -> URLRequest {
        return try target.urlRequest()
    }

    /// Builds a `URLRequest` from an ``ArachneService`` endpoint definition,
    /// modified using the `requestModifier` you set using ``with(requestModifier:)``, if any.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - timeoutInterval: Optional timeout interval in seconds.
    ///   Default value is the default of `URLRequest`: 60 seconds.
    /// - Returns: The built `URLRequest`.
    /// - Throws: `URLError` if any of the request components are invalid
    /// or the error thrown from the `requestModifier` you set using ``with(requestModifier:)``.
    @available(
        *,
         deprecated,
         renamed: "finalRequest(target:)",
         // swiftlint:disable line_length
         message: "Use finalRequest(target:) instead, timeoutInterval is now defined in ArachneService and the value passed as input to this method is ignored")
    // swiftlint:enable line_length
    public nonisolated func buildCompleteRequest(target: T, timeoutInterval: Double? = nil) async throws -> URLRequest {
        return try await urlRequest(for: target)
    }

    /// Builds a `URLRequest` from an ``ArachneService`` endpoint definition,
    /// modified using the `requestModifier` you set using ``with(requestModifier:)``, if any.
    /// - Parameters:
    ///   - target: An endpoint.
    /// - Returns: The built `URLRequest`.
    /// - Throws: `URLError` if any of the request components are invalid
    /// or the error thrown from the `requestModifier` you set using ``with(requestModifier:)``.
    public nonisolated func urlRequest(for target: T) async throws -> URLRequest {
        var request = try target.urlRequest()
        try await modify(request: &request, target: target)
        return request
    }

    // MARK: - Internal methods

    private nonisolated func modify(request: inout URLRequest, target: T) async throws {
        if let requestModifier = requestModifier {
            try await requestModifier(target, &request)
        }
    }

    nonisolated func handleResponse<DataType>(target: T,
                                              data: DataType,
                                              output: AROutput,
                                              response: URLResponse) throws -> (DataType, URLResponse) {
        guard let httpResponse = response as? HTTPURLResponse,
              target.validCodes.contains(httpResponse.statusCode) else {
            throw ARError.unacceptableStatusCode(statusCode: (response as? HTTPURLResponse)?.statusCode,
                                                 response: response as? HTTPURLResponse,
                                                 responseContent: output)
        }
        if let expectedMimeType = target.expectedMimeType, httpResponse.mimeType != expectedMimeType {
            throw ARError.unexpectedMimeType(mimeType: httpResponse.mimeType,
                                             response: httpResponse,
                                             responseContent: output)
        }
        plugins?.forEach { $0.handle(response: response, output: output) }
        return (data, response)
    }

    nonisolated func handleAndReturn(error: Error, request: URLRequest) -> Error {
        let output = extractOutput(from: error)
        plugins?.forEach { $0.handle(error: error, request: request, output: output) }
        return error
    }

    private nonisolated func extractOutput(from error: Error) -> AROutput? {
        var output: AROutput?
        if case ARError.unacceptableStatusCode(_, _, let responseContent) = error {
            output = responseContent
        }
        return output
    }
}
