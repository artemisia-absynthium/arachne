//
// ArachnePlugin.swift - protocol for implementing plugins
// This source file is part of the Arachne open source project
//
// Copyright (c) 2021 - 2023 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation

/// Implement this protocol if you want to handle the request steps, e.g. logging messages.
public protocol ArachnePlugin {
    /// This function gets called immediately before the request is sent.
    /// - Parameter request: the final request before it's sent.
    func handle(request: URLRequest)

    /// This function gets called immediately before returning a response.
    /// - Parameters:
    ///   - response: the `URLResponse`.
    ///   - data: the data retrieved from the resource, it can be
    ///     - `Data`, containing the response body, in case you used
    ///    ``ArachneProvider/data(_:timeoutInterval:session:)``
    ///     - `URL`, the temporary downloaded file URL,
    ///    in case you used ``ArachneProvider/download(_:timeoutInterval:session:)-1g9ve``
    func handle(response: URLResponse, data: Any)

    /// This function gets called whenever an error occurs, immediately before throwing it,
    /// - Parameters:
    ///   - error: the error that will be thrown.
    ///   - request: the `URLRequest` that generated the error.
    ///   - output: the optional output retrieved from the resource, it can be
    ///     - `Data`, containing the response body, in case you used
    ///    ``ArachneProvider/data(_:timeoutInterval:session:)``
    ///     - `URL`, the temporary downloaded file URL,
    ///    in case you used ``ArachneProvider/download(_:timeoutInterval:session:)-1g9ve``
    func handle(error: Error, request: URLRequest, output: Any?)
}
