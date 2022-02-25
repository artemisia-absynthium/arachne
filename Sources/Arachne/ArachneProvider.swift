//
//  ArachneProvider.swift
//  
//
//  Created by Cristina De Rito on 30/09/21.
//

import Foundation
import Combine

/// Use `ArachneProvider` to make requests to a specific `ArachneService`.
open class ArachneProvider<T: ArachneService> {

    private let urlSession: URLSession
    private let plugins: [ArachnePlugin]?
    private let signingPublisher: ((T, URLRequest) -> AnyPublisher<URLRequest, URLError>)?

    private var cancellables = Set<AnyCancellable>()

    /// Initialize a provider.
    /// - Parameters:
    ///   - urlSession: Your `URLSession`, uses default if none is passed.
    ///   - plugins: An optional array of `ArachnePlugin`s.
    ///   - signingPublisher: An optional `(T, URLRequest) -> AnyPublisher<URLRequest, URLError>` publisher that outputs the request received as input signed
    public init(urlSession: URLSession = URLSession(configuration: .default),
         plugins: [ArachnePlugin]? = nil,
         signingPublisher: ((T, URLRequest) -> AnyPublisher<URLRequest, URLError>)? = nil) {
        self.urlSession = urlSession
        self.plugins = plugins
        self.signingPublisher = signingPublisher
    }

    /// Make a request to an endpoint defined in an `ArachneService`.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - timeoutInterval: Optional timeout interval in seconds. Default value is the default of `URLRequest`: 60 seconds.
    ///   - session: Optionally pass any session you want to use instead of the default `URLSession.default`.
    /// - Returns: A publisher publishing a value of type `responseType` or an `Error` if anything goes wrong in the pipeline.
    open func request(_ target: T, timeoutInterval: Double? = nil, session: URLSession? = nil) -> AnyPublisher<Data, Error> {
        let request: URLRequest
        do {
            request = try buildRequest(target: target, timeoutInterval: timeoutInterval)
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
        return buildSigningPublisher(target: target, request: request)
            .flatMap { request -> URLSession.DataTaskPublisher in
                self.plugins?.forEach { $0.handle(request: request) }
                if let session = session {
                    return session.dataTaskPublisher(for: request)
                } else {
                    return self.urlSession.dataTaskPublisher(for: request)
                }
            }
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, target.validCodes.contains(httpResponse.statusCode) else {
                    throw ARError.unacceptableStatusCode(statusCode: (response as? HTTPURLResponse)?.statusCode,
                                                         response: response as? HTTPURLResponse,
                                                         responseContent: data)
                }
                self.plugins?.forEach { $0.handle(response: response, data: data) }
                return data
            }
            .mapError { error in
                let output = self.extractOutput(from: error)
                self.plugins?.forEach { $0.handle(error: error, output: output) }
                return error
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Download a resource from an endpoint defined in an `ArachneService`.
    /// The downloaded file must be copied in the appropriate folder to be used, because Arachne makes no assumption on whether it must be cached or not so it just returns the same URL returned from `URLSession.downloadTask`.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - timeoutInterval: Optional timeout interval in seconds. Default value is the default of `URLRequest`: 60 seconds.
    ///   - session: Optionally pass any session you want to use instead of the default `URLSession.default`.
    /// - Returns: A publisher publishing a tuple containing the temporary URL of the downloaded file and the `URLResponse` or an `Error` if anything goes wrong in the pipeline.
    open func download(_ target: T, timeoutInterval: Double? = nil, session: URLSession? = nil) -> AnyPublisher<(URL, URLResponse), Error> {
        let request: URLRequest
        do {
            request = try buildRequest(target: target, timeoutInterval: timeoutInterval)
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
        return buildSigningPublisher(target: target, request: request)
            .flatMap { request -> URLSession.DownloadTaskPublisher in
                self.plugins?.forEach { $0.handle(request: request) }
                if let session = session {
                    return session.downloadTaskPublisher(for: request)
                } else {
                    return self.urlSession.downloadTaskPublisher(for: request)
                }
            }
            .tryMap { url, response in
                guard let httpResponse = response as? HTTPURLResponse, target.validCodes.contains(httpResponse.statusCode) else {
                    throw ARError.unacceptableStatusCode(statusCode: (response as? HTTPURLResponse)?.statusCode,
                                                         response: response as? HTTPURLResponse,
                                                         responseContent: url)
                }
                self.plugins?.forEach { $0.handle(response: response, data: url) }
                return (url, response)
            }
            .mapError { error in
                let output = self.extractOutput(from: error)
                self.plugins?.forEach { $0.handle(error: error, output: output) }
                return error
            }
            .eraseToAnyPublisher()

    }

    /// Builds a `URLRequest` from an `ArachneService` endpoint definition.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - timeoutInterval: Optional timeout interval in seconds. Default value is the default of `URLRequest`: 60 seconds.
    /// - Returns: The built `URLRequest`.
    public func buildRequest(target: T, timeoutInterval: Double?) throws -> URLRequest {
        let url = try URLUtil.composedUrl(for: target)
        return URLUtil.composedRequest(for: target, url: url, timeoutInterval: timeoutInterval)
    }

    private func buildSigningPublisher(target: T, request: URLRequest) -> AnyPublisher<URLRequest, URLError> {
        let pub: AnyPublisher<URLRequest, URLError>
        if let signingPub = signingPublisher {
            pub = signingPub(target, request)
                .eraseToAnyPublisher()
        } else {
            pub = Just(request)
                .setFailureType(to: URLError.self)
                .eraseToAnyPublisher()
        }
        return pub
    }

    // MARK: - Internal methods

    private func extractOutput(from error: Error) -> Any? {
        var output: Any? = nil
        if let error = error as? ARError, case .unacceptableStatusCode(_, _, let responseContent) = error {
            output = responseContent
        }
        return output
    }

}
