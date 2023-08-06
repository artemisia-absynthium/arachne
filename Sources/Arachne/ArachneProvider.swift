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
    /// After initializing an ``ArachneProvider`` you can add plugins and a request modifier to it by chaining calls to ``with(plugins:)`` and ``with(requestModifier:)``.
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
    /// - Throws: `URLError` if any of the request components are invalid or the error thrown from the `requestModifier` you set using ``with(requestModifier:)``.
    ///   ``ARError/unacceptableStatusCode(statusCode:response:responseContent:)``
    ///   if the response code doesn't fall in your ``ArachneService/validCodes-85b1u``.
    ///   ``ARError/unexpectedMimeType(mimeType:response:responseContent:)``
    ///   if the response mime type doesn't match ``ArachneService/expectedMimeType-4w7gr``.
    @available(*, deprecated, renamed: "data(target:session:)", message: "Use data(target:session:) instead, timeoutInterval is now defined in ArachneService and the value passed as input to this method is ignored")
    public func data(_ target: T,
                     timeoutInterval: Double? = nil,
                     session: URLSession? = nil) async throws -> (Data, URLResponse) {
        return try await data(target, session: session)
    }

    /// Make a request to an endpoint defined in an ``ArachneService``.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - session: Optionally pass any session you want to use instead of the one of the provider.
    /// - Returns: The data retrieved from the endpoint, along with the response.
    /// - Throws: `URLError` if any of the request components are invalid or the error thrown from the `requestModifier` you set using ``with(requestModifier:)``.
    ///   ``ARError/unacceptableStatusCode(statusCode:response:responseContent:)``
    ///   if the response code doesn't fall in your ``ArachneService/validCodes-85b1u``.
    ///   ``ARError/unexpectedMimeType(mimeType:response:responseContent:)``
    ///   if the response mime type doesn't match ``ArachneService/expectedMimeType-4w7gr``.
    public func data(_ target: T, session: URLSession? = nil) async throws -> (Data, URLResponse) {
        let request = try await finalRequest(target: target)
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
            do {
                let (data, response) = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Data, URLResponse), Error>) in
                    currentSession.dataTask(with: request) { data, response, error in
                        guard let data = data, let response = response, error == nil else {
                            return continuation.resume(throwing: error!)
                        }
                        continuation.resume(returning: (data, response))
                    }.resume()
                }
                return try handleDataResponse(target: target, data: data, response: response)
            } catch {
                throw handleAndReturn(error: error, request: request)
            }
        }
    }

    /// Download a resource from an endpoint defined in an ``ArachneService``.
    ///
    /// **Since iOS 15, macOS 12, tvOS 15, watchOS 8** the downloaded file must be copied in the appropriate folder to be used, because Arachne makes no assumption
    /// on whether it must be cached or not so it just returns the same URL returned from `URLSession.download`.
    ///
    /// **On lower OS versions** the temporary file is copied in the user cache folder so you are responsible for removing the file
    /// when your app no longer needs it.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - timeoutInterval: Optional timeout interval in seconds.
    ///   Default value is the default of `URLRequest`: 60 seconds.
    ///   - session: Optionally pass any session you want to use instead of the one of the provider.
    /// - Returns: The URL of the saved file, along with the response.
    /// - Throws: `URLError` if any of the request components are invalid or the error thrown from the `requestModifier` you set using ``with(requestModifier:)``.
    ///   ``ARError/unacceptableStatusCode(statusCode:response:responseContent:)``
    ///   if the response code doesn't fall in your ``ArachneService/validCodes-85b1u``.
    ///   ``ARError/unexpectedMimeType(mimeType:response:responseContent:)``
    ///   if the response mime type doesn't match ``ArachneService/expectedMimeType-4w7gr``.
    @available(*, deprecated, renamed: "download(target:session:)", message: "Use download(target:session:) instead, timeoutInterval is now defined in ArachneService and the value passed as input to this method is ignored")
    public func download(_ target: T,
                         timeoutInterval: Double? = nil,
                         session: URLSession? = nil) async throws -> (URL, URLResponse) {
        return try await download(target, session: session)
    }

    /// Download a resource from an endpoint defined in an ``ArachneService``.
    ///
    /// **Since iOS 15, macOS 12, tvOS 15, watchOS 8** the downloaded file must be copied in the appropriate folder to be used, because Arachne makes no assumption
    /// on whether it must be cached or not so it just returns the same URL returned from `URLSession.download`.
    ///
    /// **On lower OS versions** the temporary file is copied in the user cache folder so you are responsible for removing the file
    /// when your app no longer needs it.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - session: Optionally pass any session you want to use instead of the one of the provider.
    /// - Returns: The URL of the saved file, along with the response.
    /// - Throws: `URLError` if any of the request components are invalid or the error thrown from  the`requestModifier` you set using ``with(requestModifier:)``.
    ///   ``ARError/unacceptableStatusCode(statusCode:response:responseContent:)``
    ///   if the response code doesn't fall in your ``ArachneService/validCodes-85b1u``.
    ///   ``ARError/unexpectedMimeType(mimeType:response:responseContent:)``
    ///   if the response mime type doesn't match ``ArachneService/expectedMimeType-4w7gr``.
    public func download(_ target: T, session: URLSession? = nil) async throws -> (URL, URLResponse) {
        let request = try await finalRequest(target: target)
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
            do {
                let (url, response) = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(URL, URLResponse), Error>) in
                    currentSession.downloadTask(with: request) { url, response, error in
                        do {
                            guard let url = url, let response = response, error == nil else {
                                throw error ?? ARError.missingData(url, response)
                            }
                            let tempDestination = try FileManager.default
                                .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                                .appendingPathComponent(url.lastPathComponent)
                            if FileManager.default.fileExists(atPath: tempDestination.path) {
                                try FileManager.default.removeItem(at: tempDestination)
                            }
                            try FileManager.default.copyItem(at: url, to: tempDestination)
                            continuation.resume(returning: (tempDestination, response))
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }.resume()
                }
                return try handleDownloadResponse(target: target, url: url, response: response)
            } catch {
                throw handleAndReturn(error: error, request: request)
            }
        }
    }

    /// Download a resource from an endpoint defined in an ``ArachneService`` and allows to follow download progress and task cancellation.
    ///
    /// You can't pass a `URLSession` to this method because one will be created with a delegate managed by Arachne.
    /// Instead you can pass a session configuration that will be used by the created session.
    ///
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - sessionConfiguration: Optional session configuration to init the session. If `nil`, the provider session configuration will be used.
    ///   - didWriteData: Called whenever data is written to file system with `bytesWritten`, `totalBytesWritten` and `totalBytesExpectedToWrite` parameters.
    ///   - didCompleteTask: Called when the task is completed, it returns a `Swift.Result` object with the URL of the saved file,
    ///   along with the response in case of success and the same errors thrown by ``download(_:session:)`` in case of failure.
    /// - Returns: The download task, that can be used to cancel the download and get `Data` to resume it. You should keep a reference to the task to allow cancellation.
    /// After cancelling the task you can resume it using ``download(_:withResumeData:sessionConfiguration:didResumeDownload:didWriteData:didCompleteTask:)``.
    /// - Throws: `URLError` if any of the request components are invalid or the error thrown from  the`requestModifier` you set using ``with(requestModifier:)``.
    public func download(_ target: T,
                         sessionConfiguration: URLSessionConfiguration? = nil,
                         didWriteData: @escaping (Int64, Int64, Int64) -> Void,
                         didCompleteTask: @escaping (Result<(URL, URLResponse), Error>) -> Void) async throws -> URLSessionDownloadTask {
        let request = try await finalRequest(target: target)
        self.plugins?.forEach { $0.handle(request: request) }
        let delegate = ArachneDownloadDelegate { _, _ in
                // Nothing to do, this method is not used to resume download tasks
            } didWriteData: { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                didWriteData(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
            } didCompleteTask: { url, response, error in
                do {
                    guard let url = url, let response = response, error == nil else {
                        throw error ?? ARError.missingData(url, response)
                    }
                    didCompleteTask(.success(
                        try handleDownloadResponse(target: target, url: url, response: response)
                    ))
                } catch {
                    didCompleteTask(.failure(handleAndReturn(error: error, request: request)))
                }
            }

        let session = URLSession(configuration: sessionConfiguration ?? urlSession.configuration, delegate: delegate, delegateQueue: nil)
        let task = session.downloadTask(with: request)
        task.resume()
        return task
    }

    /// Resumes a download started using ``download(_:sessionConfiguration:didWriteData:didCompleteTask:)``
    /// from an endpoint defined in an ``ArachneService`` and allows to follow download progress and task cancellation.
    ///
    /// The `Data` parameter has been obtained by calling `URLSessionDownloadTask.cancelByProducingResumeData()`.
    ///
    /// You can't pass a `URLSession` to this method because one will be created with a delegate managed by Arachne.
    /// Instead you can pass a session configuration that will be used by the created session.
    /// A good practice is to use the same session configuration used when calling ``download(_:sessionConfiguration:didWriteData:didCompleteTask:)``.
    ///
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - withResumeData: The partial download `Data`.
    ///   - sessionConfiguration: Optional session configuration to init the session. If `nil`, the provider session configuration will be used.
    ///   - didResumeDownload: Called when download resumes with `fileOffset` and `expectedTotalBytes` parameters.
    ///   - didWriteData: Called whenever data is written to file system with `bytesWritten`, `totalBytesWritten` and `totalBytesExpectedToWrite` parameters.
    ///   - didCompleteTask: Called when the task is completed, it returns a `Swift.Result` object with the URL of the saved file,
    ///   along with the response in case of success and the same errors thrown by ``download(_:session:)`` in case of failure.
    /// - Returns: The download task, that can be used to cancel the download and get `Data` to resume it. You should keep a reference to the task to allow cancellation.
    /// After cancelling the task you can resume it using ``download(_:withResumeData:sessionConfiguration:didResumeDownload:didWriteData:didCompleteTask:)``.
    /// - Throws: `URLError` if any of the request components are invalid or the error thrown from  the`requestModifier` you set using ``with(requestModifier:)``.
    public func download(_ target: T,
                         withResumeData data: Data,
                         sessionConfiguration: URLSessionConfiguration? = nil,
                         didResumeDownload: @escaping (Int64, Int64) -> Void,
                         didWriteData: @escaping (Int64, Int64, Int64) -> Void,
                         didCompleteTask: @escaping (Result<(URL, URLResponse), Error>) -> Void) async throws -> URLSessionDownloadTask {
        let request = try await finalRequest(target: target)
        let delegate = ArachneDownloadDelegate { fileOffset, expectedTotalBytes in
                didResumeDownload(fileOffset, expectedTotalBytes)
            } didWriteData: { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                didWriteData(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
            } didCompleteTask: { url, response, error in
                do {
                    guard let url = url, let response = response, error == nil else {
                        throw error ?? ARError.missingData(url, response)
                    }
                    didCompleteTask(.success(
                        try handleDownloadResponse(target: target, url: url, response: response)
                    ))
                } catch {
                    didCompleteTask(.failure(handleAndReturn(error: error, request: request)))
                }
            }

        let session = URLSession(configuration: sessionConfiguration ?? urlSession.configuration, delegate: delegate, delegateQueue: nil)
        let task = session.downloadTask(withResumeData: data)
        task.resume()
        return task
    }

    // MARK: - URLRequest

    /// Builds a `URLRequest` from an ``ArachneService`` endpoint definition.
    ///
    /// The output request is not modified using the `requestModifier` you set using ``with(requestModifier:)``, you may want to use ``finalRequest(target:)``.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - timeoutInterval: Optional timeout interval in seconds.
    ///   Default value is the default of `URLRequest`: 60 seconds.
    /// - Returns: The built `URLRequest`.
    /// - Throws: `URLError` if any of the request components are invalid.
    @available(*, deprecated, message: "Use ArachneService.urlRequest() instead, timeoutInterval is now defined in ArachneService and the value passed as input to this method is ignored")
    public func buildRequest(target: T, timeoutInterval: Double? = nil) throws -> URLRequest {
        return try target.urlRequest()
    }

    /// Builds a `URLRequest` from an ``ArachneService`` endpoint definition, modified using the `requestModifier` you set using ``with(requestModifier:)``, if any.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - timeoutInterval: Optional timeout interval in seconds.
    ///   Default value is the default of `URLRequest`: 60 seconds.
    /// - Returns: The built `URLRequest`.
    /// - Throws: `URLError` if any of the request components are invalid or the error thrown from the `requestModifier` you set using ``with(requestModifier:)``.
    @available(*, deprecated, renamed: "finalRequest(target:)", message: "Use finalRequest(target:) instead, timeoutInterval is now defined in ArachneService and the value passed as input to this method is ignored")
    public func buildCompleteRequest(target: T, timeoutInterval: Double? = nil) async throws -> URLRequest {
        return try await finalRequest(target: target)
    }

    /// Builds a `URLRequest` from an ``ArachneService`` endpoint definition, modified using the `requestModifier` you set using ``with(requestModifier:)``, if any.
    /// - Parameters:
    ///   - target: An endpoint.
    /// - Returns: The built `URLRequest`.
    /// - Throws: `URLError` if any of the request components are invalid or the error thrown from the `requestModifier` you set using ``with(requestModifier:)``.
    public func finalRequest(target: T) async throws -> URLRequest {
        var request = try target.urlRequest()
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
        if let expectedMimeType = target.expectedMimeType, httpResponse.mimeType != expectedMimeType {
            throw ARError.unexpectedMimeType(mimeType: httpResponse.mimeType, response: httpResponse, responseContent: data)
        }
        self.plugins?.forEach { $0.handle(response: response, data: data) }
        return (data, response)
    }

    private func handleDownloadResponse(target: T, url: URL, response: URLResponse) throws -> (URL, URLResponse) {
        guard let httpResponse = response as? HTTPURLResponse,
              target.validCodes.contains(httpResponse.statusCode) else {
            throw ARError.unacceptableStatusCode(statusCode: (response as? HTTPURLResponse)?.statusCode,
                                                 response: response as? HTTPURLResponse,
                                                 responseContent: url)
        }
        if let expectedMimeType = target.expectedMimeType, httpResponse.mimeType != expectedMimeType {
            throw ARError.unexpectedMimeType(mimeType: httpResponse.mimeType, response: httpResponse, responseContent: data)
        }
        self.plugins?.forEach { $0.handle(response: response, data: url) }
        return (url, response)
    }

    private func handleAndReturn(error: Error, request: URLRequest) -> Error {
        let output = extractOutput(from: error)
        self.plugins?.forEach { $0.handle(error: error, request: request, output: output) }
        return error
    }

    private func extractOutput(from error: Error) -> Any? {
        var output: Any?
        if case ARError.unacceptableStatusCode(_, _, let responseContent) = error {
            output = responseContent
        }
        return output
    }
}
