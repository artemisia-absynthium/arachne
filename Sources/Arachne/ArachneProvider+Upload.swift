//
// ArachneProvider+Upload.swift - the provider upload methods implementation
// This source file is part of the Arachne open source project
//
// Copyright (c) 2021 - 2025 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
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
            let (responseData, response) = try await currentSession.upload(for: request, from: bodyData)
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
            let (responseData, response) = try await currentSession.upload(for: request, fromFile: fileURL)
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
