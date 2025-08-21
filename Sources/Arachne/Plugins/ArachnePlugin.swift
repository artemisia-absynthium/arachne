//
// ArachnePlugin.swift - protocol for implementing plugins
// This source file is part of the Arachne open source project
//
// Copyright (c) 2021 - 2024 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation

/// Implement this protocol if you want to handle the request steps, e.g. logging messages.
public protocol ArachnePlugin: Sendable {
    /// This function gets called immediately before the request is sent.
    /// - Parameter request: the final request before it's sent.
    func handle(request: URLRequest)

    /// This function gets called immediately before a response is returned.
    /// - Parameters:
    ///   - response: the `URLResponse`.
    ///   - output: the output retrieved from the resource, conveniently wrapped in an enum with the possible data types
    func handle(response: URLResponse, output: AROutput)

    /// This function gets called whenever an error occurs, immediately before it is thrown.
    /// - Parameters:
    ///   - error: the error that will be thrown.
    ///   - request: the `URLRequest` that generated the error.
    ///   - output: the output, if any, retrieved from the resource, conveniently wrapped in an enum with the possible data types
    func handle(error: any Error, request: URLRequest, output: AROutput?)
}
