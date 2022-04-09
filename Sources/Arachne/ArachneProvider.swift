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
    private let signingFunction: ((T, URLRequest) async throws -> URLRequest)?

    /// Initialize a provider that uses a Combine Publisher to sign requests.
    /// - Parameters:
    ///   - urlSession: Your `URLSession`, uses default if none is passed.
    ///   - plugins: An optional array of `ArachnePlugin`s.
    ///   - signingPublisher: An optional Combine Publisher `(T, URLRequest) -> AnyPublisher<URLRequest, URLError>`
    ///   publisher that outputs the request received as input signed.
    public init(urlSession: URLSession = URLSession(configuration: .default),
                plugins: [ArachnePlugin]? = nil,
                signingPublisher: ((T, URLRequest) -> AnyPublisher<URLRequest, URLError>)? = nil) {
        self.urlSession = urlSession
        self.plugins = plugins
        self.signingPublisher = signingPublisher
        self.signingFunction = nil
    }

    /// Initialize a provider that uses an asynchronous function to sign requests.
    /// - Parameters:
    ///   - urlSession: Your `URLSession`, uses default if none is passed.
    ///   - plugins: An optional array of `ArachnePlugin`s.
    ///   - signingFunction: An optional async throwing function that signs the request before it is made.
    public init(urlSession: URLSession = URLSession(configuration: .default),
                signingFunction: ((T, URLRequest) async throws -> URLRequest)?,
                plugins: [ArachnePlugin]?) {
        self.urlSession = urlSession
        self.plugins = plugins
        self.signingPublisher = nil
        self.signingFunction = signingFunction
    }

    // MARK: - Combine

    /// Make a request to an endpoint defined in an `ArachneService`.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - timeoutInterval: Optional timeout interval in seconds.
    ///   Default value is the default of `URLRequest`: 60 seconds.
    ///   - session: Optionally pass any session you want to use instead of the one of the provider.
    /// - Returns: A publisher publishing a value of type `responseType`
    /// or an `Error` if anything goes wrong in the pipeline.
    open func request(_ target: T,
                      timeoutInterval: Double? = nil,
                      session: URLSession? = nil) -> AnyPublisher<Data, Error> {
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
                return (session ?? self.urlSession).dataTaskPublisher(for: request)
            }
            .tryMap { data, response in
                return try self.handleDataResponse(target: target, data: data, response: response)
            }
            .mapError { error in
                return self.handleAndReturn(error: error, request: request)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Download a resource from an endpoint defined in an `ArachneService`.
    /// The downloaded file must be copied in the appropriate folder to be used, because Arachne makes no assumption
    /// on whether it must be cached or not so it just returns the same URL returned from `URLSession.downloadTask`.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - timeoutInterval: Optional timeout interval in seconds.
    ///   Default value is the default of `URLRequest`: 60 seconds.
    ///   - session: Optionally pass any session you want to use instead of the one of the provider.
    /// - Returns: A publisher publishing a tuple containing the temporary URL of the downloaded file
    /// and the `URLResponse` or an `Error` if anything goes wrong in the pipeline.
    open func download(_ target: T,
                       timeoutInterval: Double? = nil,
                       session: URLSession? = nil) -> AnyPublisher<(URL, URLResponse), Error> {
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
                return (session ?? self.urlSession).downloadTaskPublisher(for: request)
            }
            .tryMap { url, response in
                return try self.handleDownloadResponse(target: target, url: url, response: response)
            }
            .mapError { error in
                return self.handleAndReturn(error: error, request: request)
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Async/Await

    /// Make a request to an endpoint defined in an `ArachneService`.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - timeoutInterval: Optional timeout interval in seconds.
    ///   Default value is the default of `URLRequest`: 60 seconds.
    ///   - session: Optionally pass any session you want to use instead of the one of the provider.
    /// - Returns: The data retrieved from the endpoint, along with the response.
    public func data(_ target: T,
                     timeoutInterval: Double? = nil,
                     session: URLSession? = nil) async throws -> (Data, URLResponse) {
        var request = try buildRequest(target: target, timeoutInterval: timeoutInterval)
        request = try await sign(request: request, target: target)
        self.plugins?.forEach { $0.handle(request: request) }
        let (data, response) = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Data, URLResponse), Error>) in
            (session ?? self.urlSession).dataTask(with: request) { data, response, error in
                guard let data = data, let response = response, error == nil else {
                    continuation.resume(throwing: self.handleAndReturn(error: error!, request: request))
                    return
                }
                do {
                    let (data, response) = try self.handleDataResponse(target: target, data: data, response: response)
                    continuation.resume(returning: (data, response))
                } catch {
                    continuation.resume(throwing: self.handleAndReturn(error: error, request: request))
                }
            }.resume()
        }
        return (data, response)
    }

    /// Download a resource from an endpoint defined in an `ArachneService`.
    /// The downloaded file must be copied in the appropriate folder to be used, because Arachne makes no assumption
    /// on whether it must be cached or not so it just returns the same URL returned from `URLSession.downloadTask`.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - timeoutInterval: Optional timeout interval in seconds.
    ///   Default value is the default of `URLRequest`: 60 seconds.
    ///   - session: Optionally pass any session you want to use instead of the one of the provider.
    /// - Returns: The URL of the saved file, along with the response.
    public func download(_ target: T,
                         timeoutInterval: Double? = nil,
                         session: URLSession? = nil) async throws -> (URL, URLResponse) {
        var request = try buildRequest(target: target, timeoutInterval: timeoutInterval)
        request = try await sign(request: request, target: target)
        self.plugins?.forEach { $0.handle(request: request) }
        let (url, response) = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(URL, URLResponse), Error>) in
            (session ?? self.urlSession).downloadTask(with: request) { url, response, error in
                guard let url = url, let response = response, error == nil else {
                    continuation.resume(throwing: self.handleAndReturn(error: error!, request: request))
                    return
                }
                do {
                    let (url, response) = try self.handleDownloadResponse(target: target, url: url, response: response)
                    continuation.resume(returning: (url, response))
                } catch {
                    continuation.resume(throwing: self.handleAndReturn(error: error, request: request))
                }
            }.resume()
        }
        return (url, response)
    }

    // MARK: - URLRequest

    /// Builds a `URLRequest` from an `ArachneService` endpoint definition.
    /// - Parameters:
    ///   - target: An endpoint.
    ///   - timeoutInterval: Optional timeout interval in seconds.
    ///   Default value is the default of `URLRequest`: 60 seconds.
    /// - Returns: The built `URLRequest`.
    public func buildRequest(target: T, timeoutInterval: Double?) throws -> URLRequest {
        let url = try URLUtil.composedUrl(for: target)
        return URLUtil.composedRequest(for: target, url: url, timeoutInterval: timeoutInterval)
    }

    // MARK: - Internal methods

    private func sign(request: URLRequest, target: T) async throws -> URLRequest {
        var signedRequest = request
        if let signingFunction = signingFunction {
            signedRequest = try await signingFunction(target, request)
        } else if let signingPublisher = signingPublisher {
            var cancellable: AnyCancellable?
            signedRequest = try await withCheckedThrowingContinuation { continuation in
                cancellable = signingPublisher(target, request)
                    .sink(receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }, receiveValue: { request in
                        continuation.resume(returning: request)
                    })
            }
        }
        return signedRequest
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

    private func buildSigningPublisher(target: T, request: URLRequest) -> AnyPublisher<URLRequest, URLError> {
        let pub: AnyPublisher<URLRequest, URLError>
        if let signingPub = signingPublisher {
            pub = signingPub(target, request)
                .eraseToAnyPublisher()
        } else if let signingFunction = signingFunction {
            pub = Future { promise in
                Task {
                    do {
                        let signedRequest = try await signingFunction(target, request)
                        promise(.success(signedRequest))
                    } catch let error as URLError {
                        promise(.failure(error))
                    } catch {
                        promise(.failure(URLError(.userAuthenticationRequired, userInfo: [NSUnderlyingErrorKey: error])))
                    }
                }
            }
            .eraseToAnyPublisher()
        } else {
            pub = Just(request)
                .setFailureType(to: URLError.self)
                .eraseToAnyPublisher()
        }
        return pub
    }

    private func extractOutput(from error: Error) -> Any? {
        var output: Any?
        if let error = error as? ARError, case .unacceptableStatusCode(_, _, let responseContent) = error {
            output = responseContent
        }
        return output
    }
}
