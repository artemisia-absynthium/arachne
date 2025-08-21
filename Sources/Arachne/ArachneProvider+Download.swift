//
//  ArachneProvider+Download.swift
//  Arachne
//
//  Created by Cristina De Rito on 21/08/25.
//

import Foundation

extension ArachneProvider {
    /// Download a resource from an endpoint defined in an ``ArachneService``.
    ///
    /// **Since iOS 15, macOS 12, tvOS 15, watchOS 8** the downloaded file must be copied
    /// in the appropriate folder to be used, because Arachne makes no assumption
    /// on whether it must be cached or not so it just returns the same URL returned from `URLSession.download`.
    ///
    /// **On lower OS versions** the temporary file is copied
    /// in the user cache folder so you are responsible for removing the file
    /// when your app no longer needs it.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - timeoutInterval: Optional timeout interval in seconds.
    ///   Default value is the default of `URLRequest`: 60 seconds.
    ///   - session: Optionally pass any session you want to use instead of the one of the provider.
    /// - Returns: The URL of the saved file, along with the response.
    /// - Throws: `URLError` if any of the request components are invalid
    /// or the error thrown from the `requestModifier` you set using ``with(requestModifier:)``.
    ///   ``ARError/unacceptableStatusCode(statusCode:response:responseContent:)``
    ///   if the response code doesn't fall in your ``ArachneService/validCodes-85b1u``.
    ///   ``ARError/unexpectedMimeType(mimeType:response:responseContent:)``
    ///   if the response mime type doesn't match ``ArachneService/expectedMimeType-4w7gr``.
    ///   If the download can be resumed, there will be data in the error's ``Error.downloadResumeData``.
    @available(
        *,
         deprecated,
         renamed: "download(target:session:)",
         // swiftlint:disable line_length
         message: "Use download(target:session:) instead, timeoutInterval is now defined in ArachneService and the value passed as input to this method is ignored")
    // swiftlint:enable line_length
    public nonisolated func download(_ target: T,
                                     timeoutInterval: Double? = nil,
                                     session: URLSession? = nil) async throws -> (URL, URLResponse) {
        return try await download(target, session: session)
    }

    /// Download a resource from an endpoint defined in an ``ArachneService``.
    ///
    /// **Since iOS 15, macOS 12, tvOS 15, watchOS 8** the downloaded file must be copied
    /// in the appropriate folder to be used, because Arachne makes no assumption
    /// on whether it must be cached or not so it just returns the same URL returned from `URLSession.download`.
    ///
    /// **On lower OS versions** the temporary file is copied
    /// in the user cache folder so you are responsible for removing the file
    /// when your app no longer needs it.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - session: Optionally pass any session you want to use instead of the one of the provider.
    /// - Returns: The URL of the saved file, along with the response.
    /// - Throws: `URLError` if any of the request components are invalid
    /// or the error thrown from  the`requestModifier` you set using ``with(requestModifier:)``.
    ///   ``ARError/unacceptableStatusCode(statusCode:response:responseContent:)``
    ///   if the response code doesn't fall in your ``ArachneService/validCodes-85b1u``.
    ///   ``ARError/unexpectedMimeType(mimeType:response:responseContent:)``
    ///   if the response mime type doesn't match ``ArachneService/expectedMimeType-4w7gr``.
    ///   If the download can be resumed, there will be data in the error's ``Error.downloadResumeData``.
    public nonisolated func download(_ target: T, session: URLSession? = nil) async throws -> (URL, URLResponse) {
        let request = try await urlRequest(for: target)
        self.plugins?.forEach { $0.handle(request: request) }
        let currentSession = session ?? self.urlSession
        if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            do {
                let (url, response) = try await currentSession.download(for: request)
                return try handleResponse(target: target, data: url, output: .url(url), response: response)
            } catch {
                throw handleAndReturn(error: error, request: request)
            }
        } else {
            do {
                let (url, response) = try await withCheckedThrowingContinuation { continuation in
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
                return try handleResponse(target: target, data: url, output: .url(url), response: response)
            } catch {
                throw handleAndReturn(error: error, request: request)
            }
        }
    }

    /// Download a resource from an endpoint defined in an ``ArachneService``
    /// and allows to follow download progress and task cancellation.
    ///
    /// You can't pass a `URLSession` to this method because one will be created with a delegate managed by Arachne.
    /// Instead you can pass a session configuration that will be used by the created session.
    /// If you need to use your delegate, just build the URLRequest for your endpoint
    /// using ``urlRequest(for:)`` and use `URLSession`'s download functions directly.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - sessionConfiguration: Optional session configuration to init the session.
    ///   If `nil`, the provider session configuration will be used.
    ///   - didWriteData: Called whenever data is written to file system with
    ///   `bytesWritten`, `totalBytesWritten` and `totalBytesExpectedToWrite` parameters.
    ///   - didCompleteTask: Called when the task is completed,
    ///    it returns a `Swift.Result` object with the URL of the saved file,
    ///   along with the response in case of success and the same
    ///   errors thrown by ``download(_:session:)`` in case of failure.
    /// - Returns: The download task, that can be used to cancel the download and
    /// get `Data` to resume it. You should keep a reference to the task to allow cancellation.
    /// After cancelling the task you can resume it using
    /// ``download(_:withResumeData:sessionConfiguration:didResumeDownload:didWriteData:didCompleteTask:)``.
    /// - Throws: `URLError` if any of the request components are invalid
    /// or the error thrown from  the`requestModifier` you set using ``with(requestModifier:)``.
    ///   ``ARError/unacceptableStatusCode(statusCode:response:responseContent:)``
    ///   if the response code doesn't fall in your ``ArachneService/validCodes-85b1u``.
    ///   ``ARError/unexpectedMimeType(mimeType:response:responseContent:)``
    ///   if the response mime type doesn't match ``ArachneService/expectedMimeType-4w7gr``.
    ///   If the download can be resumed, there will be data in the error's ``Error.downloadResumeData``.
    public nonisolated func download(_ target: T,
                                     sessionConfiguration: URLSessionConfiguration? = nil,
                                     didWriteData: @escaping @Sendable (Int64, Int64, Int64) -> Void,
                                     didCompleteTask: @escaping @Sendable (URL, URLResponse) -> Void,
                                     didFailTask: @escaping @Sendable (Error) -> Void
    ) async throws -> URLSessionDownloadTask {
        let request = try await urlRequest(for: target)
        self.plugins?.forEach { $0.handle(request: request) }
        let delegate = ArachneDownloadDelegate(
            didResumeDownload: nil,
            didWriteData: didWriteData,
            didCompleteTask: { [self] url, response in
                do {
                    guard let response else {
                        throw ARError.missingData(url, response)
                    }
                    let handledResponse = try handleResponse(
                        target: target,
                        data: url,
                        output: .url(url),
                        response: response)
                    didCompleteTask(handledResponse.0, handledResponse.1)
                } catch {
                    didFailTask(handleAndReturn(error: error, request: request))
                }
            },
            didFailTask: didFailTask)

        let session = URLSession(configuration: sessionConfiguration ?? urlSession.configuration,
                                 delegate: delegate,
                                 delegateQueue: nil)
        let task = session.downloadTask(with: request)
        task.resume()
        return task
    }

    /// Resumes a download from an endpoint defined in an ``ArachneService``
    /// using resume data, and allows to follow download progress and task cancellation.
    ///
    /// The `Data` parameter has been obtained by calling `URLSessionDownloadTask.cancelByProducingResumeData()`.
    ///
    /// You can't pass a `URLSession` to this method because one will be created with a delegate managed by Arachne.
    /// Instead you can pass a session configuration that will be used by the created session.
    /// If you need to use your delegate, just build the URLRequest for your endpoint
    /// using ``urlRequest(for:)`` and use `URLSession`'s download functions directly.
    /// A good practice is to use the same session configuration used when calling
    /// ``download(_:sessionConfiguration:didWriteData:didCompleteTask:)``.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - withResumeData: The partial download `Data`.
    ///   - sessionConfiguration: Optional session configuration to init the session.
    ///   If `nil`, the provider session configuration will be used.
    ///   - didResumeDownload: Called when download resumes with `fileOffset` and `expectedTotalBytes` parameters.
    ///   - didWriteData: Called whenever data is written to file system with
    ///   `bytesWritten`, `totalBytesWritten` and `totalBytesExpectedToWrite` parameters.
    ///   - didCompleteTask: Called when the task is completed, it returns
    ///   a `Swift.Result` object with the URL of the saved file,
    ///   along with the response in case of success and the same errors thrown
    ///   by ``download(_:session:)`` in case of failure.
    /// - Returns: The download task, that can be used to cancel the download
    /// and get `Data` to resume it. You should keep a reference to the task to allow cancellation.
    /// After cancelling the task you can resume it using
    /// ``download(_:withResumeData:sessionConfiguration:didResumeDownload:didWriteData:didCompleteTask:)``.
    /// - Throws: `URLError` if any of the request components are invalid
    /// or the error thrown from  the`requestModifier` you set using ``with(requestModifier:)``.
    ///   ``ARError/unacceptableStatusCode(statusCode:response:responseContent:)``
    ///   if the response code doesn't fall in your ``ArachneService/validCodes-85b1u``.
    ///   ``ARError/unexpectedMimeType(mimeType:response:responseContent:)``
    ///   if the response mime type doesn't match ``ArachneService/expectedMimeType-4w7gr``.
    ///   If the download can be resumed, there will be data in the error's ``Error.downloadResumeData``.
    public nonisolated func download(_ target: T,
                                     withResumeData data: Data,
                                     sessionConfiguration: URLSessionConfiguration? = nil,
                                     didResumeDownload: @escaping @Sendable (Int64, Int64) -> Void,
                                     didWriteData: @escaping @Sendable (Int64, Int64, Int64) -> Void,
                                     didCompleteTask: @escaping @Sendable (Result<(URL, URLResponse), Error>) -> Void
    ) async throws -> URLSessionDownloadTask {
        let request = try await urlRequest(for: target)
        let delegate = ArachneDownloadDelegate(
            didResumeDownload: didResumeDownload,
            didWriteData: didWriteData,
            didCompleteTask: { url, response in
                do {
                    guard let response else {
                        throw ARError.missingData(url, response)
                    }
                    let handledResponse = try handleResponse(
                        target: target,
                        data: url,
                        output: .url(url),
                        response: response)
                    didCompleteTask(.success(handledResponse))
                } catch {
                    didCompleteTask(.failure(handleAndReturn(error: error, request: request)))
                }
            },
            didFailTask: { error in
                didCompleteTask(.failure(error))
            })

        let session = URLSession(configuration: sessionConfiguration ?? urlSession.configuration,
                                 delegate: delegate,
                                 delegateQueue: nil)
        let task = session.downloadTask(withResumeData: data)
        task.resume()
        return task
    }
}
