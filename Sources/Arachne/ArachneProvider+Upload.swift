//
//  ArachneProvider+Upload.swift
//  Arachne
//
//  Created by Cristina De Rito on 21/08/25.
//

import Foundation

extension ArachneProvider {
    /// Uploads data to an endpoint and delivers the result asynchronously.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - session: Optionally pass any session you want to use instead of the one of the provider.
    ///   - bodyData: The body data for the request.
    /// - Returns: An asynchronously-delivered tuple that contains any data returned
    /// by the server as a `Data` instance, and a `URLResponse`.
    public nonisolated func upload(_ target: T,
                                   session: URLSession? = nil,
                                   from bodyData: Data) async throws -> (Data, URLResponse) {
        let request = try await urlRequest(for: target)
        plugins?.forEach { $0.handle(request: request) }
        let currentSession = session ?? urlSession
        do {
            let (responseData, response) = if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
                try await currentSession.upload(for: request, from: bodyData)
            } else {
                try await withCheckedThrowingContinuation { continuation in
                    currentSession.uploadTask(with: request, from: bodyData) { data, response, error in
                        guard let data, let response, error == nil else {
                            return continuation.resume(throwing: ARError.missingData(nil, response))
                        }
                        continuation.resume(returning: (data, response))
                    }.resume()
                }
            }
            return try handleResponse(
                target: target,
                data: responseData,
                output: .data(responseData),
                response: response)
        } catch {
            throw handleAndReturn(error: error, request: request)
        }
    }

    /// Uploads data to an endpoint and delivers the result asynchronously.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - session: Optionally pass any session you want to use instead of the one of the provider.
    ///   - fileURL: A file URL containing the data to upload.
    /// - Returns: An asynchronously-delivered tuple that contains any data returned
    /// by the server as a `Data` instance, and a `URLResponse`.
    public nonisolated func upload(_ target: T,
                                   session: URLSession? = nil,
                                   fromFile fileURL: URL) async throws -> (Data, URLResponse) {
        let request = try await urlRequest(for: target)
        plugins?.forEach { $0.handle(request: request) }
        let currentSession = session ?? urlSession
        do {
            let (responseData, response) = if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
                try await currentSession.upload(for: request, fromFile: fileURL)
            } else {
                try await withCheckedThrowingContinuation { continuation in
                    currentSession.uploadTask(with: request, fromFile: fileURL) { data, response, error in
                        guard let data, let response, error == nil else {
                            return continuation.resume(throwing: ARError.missingData(nil, response))
                        }
                        continuation.resume(returning: (data, response))
                    }.resume()
                }
            }
            return try handleResponse(
                target: target,
                data: responseData,
                output: .data(responseData),
                response: response)
        } catch {
            throw handleAndReturn(error: error, request: request)
        }
    }
}
