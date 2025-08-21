//
// ArachneProvider+Download.swift - the provider download methods implementation
// This source file is part of the Arachne open source project
//
// Copyright (c) 2021 - 2025 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation

extension ArachneProvider {
    /// Download a resource from an endpoint defined in an ``ArachneService``.
    ///
    /// The downloaded file must be copied
    /// in the appropriate folder to be used, because Arachne makes no assumption
    /// on whether it must be cached or not so it just returns the same URL returned from `URLSession.download`.
    ///
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
        do {
            let (url, response) = try await currentSession.download(for: request)
            return try handleResponse(target: target, data: url, output: .url(url), response: response)
        } catch {
            throw handleAndReturn(error: error, request: request)
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
