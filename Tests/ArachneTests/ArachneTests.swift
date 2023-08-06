//
// ArachneTests.swift - test suite
// This source file is part of the Arachne open source project
//
// Copyright (c) 2021 - 2023 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import XCTest
@testable import Arachne

final class ArachneTests: XCTestCase {
    let timeout: TimeInterval = 30
    lazy var configuration: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return configuration
    }()
    lazy var session: URLSession = URLSession(configuration: configuration)

    override class func setUp() {
        URLProtocol.registerClass(MockURLProtocol.self)
        let service1Exchanges: [MockNetworkExchange] = MyService.allCases
            .compactMap { guard let request = try? $0.urlRequest() else { return nil }
                return MockNetworkExchange(urlRequest: request, response: $0.mockResponse) }
        let service2Exchanges: [MockNetworkExchange] = MyServiceWithDefaults.allCases
            .compactMap { guard let request = try? $0.urlRequest() else { return nil }
                return MockNetworkExchange(urlRequest: request, response: $0.mockResponse) }
        MockURLProtocol.mockExchanges = Set(service1Exchanges + service2Exchanges)
    }

    override class func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
    }

    func testGet() throws {
        let expectation = XCTestExpectation(description: "Get request returns expected JSON data")

        let provider = ArachneProvider<MyService>(urlSession: session)
        Task {
            do {
                let (data, _) = try await provider.data(.jsonResponse)
                let user = try JSONDecoder().decode(MyModel.self, from: data)
                XCTAssertEqual(user, MyModel(field: "field"))
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error.localizedDescription)")
            }
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testMalformedUrlErrorBecauseOfBaseUrl() throws {
        let expectation = XCTestExpectation(description: "Service URL is malformed")

        let provider = ArachneProvider<MyServiceWithDefaults>(urlSession: session)
        Task {
            do {
                _ = try await provider.data(.malformedUrl)
                XCTFail("Shouldn't receive any value, URL is malformed")
            } catch let error as URLError {
                let expectedError = URLError(.unsupportedURL)
                XCTAssertEqual(error.errorCode, expectedError.errorCode)
                expectation.fulfill()
            } catch {
                XCTFail("Shouldn't receive any other error")
            }
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testMalformedUrlErrorBecauseOfPath() throws {
        let expectation = XCTestExpectation(description: "Endpoint path is malformed")

        let provider = ArachneProvider<MyServiceWithDefaults>(urlSession: session)
        Task {
            do {
                _ = try await provider.data(.nilUrl)
                XCTFail("Shouldn't receive any value, URL is malformed")
            } catch let error as URLError {
                var urlComponents = URLComponents(string: "https://malformedquerystring.io")
                let endpoint = MyServiceWithDefaults.nilUrl
                urlComponents?.path = endpoint.path
                urlComponents?.queryItems = endpoint.queryStringItems
                let expectedError = URLError(.unsupportedURL)
                XCTAssertEqual(error.errorCode, expectedError.errorCode)
                expectation.fulfill()
            } catch {
                XCTFail("Shouldn't receive any other error")
            }
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testReservedAppleHeaderIsNotAdded() throws {
        let endpoint = MyServiceWithDefaults.reservedHeader

        do {
            let builtRequest = try endpoint.urlRequest()
            XCTAssertNil(builtRequest.value(forHTTPHeaderField: "Content-Length"))
        } catch {
            XCTFail("Building request for endpoint \(endpoint) should not fail")
        }
    }

    func testPost() throws {
        let expectation = XCTestExpectation(description: "POST request gets executed fine and body is as expected")
        let provider = ArachneProvider<MyServiceWithDefaults>(urlSession: session)
        Task {
            do {
                let builtRequest = try MyServiceWithDefaults.postSomething.urlRequest()
                XCTAssertEqual(builtRequest.httpBody, "I'm posting something".data(using: .utf8))
                _ = try await provider.data(.postSomething)
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error.localizedDescription)")
            }
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testDownload() throws {
        let expectation = XCTestExpectation(description: "Download an image")

        let provider = ArachneProvider<MyService>(urlSession: session)
        Task {
            do {
                let (url, response) = try await provider.download(.fileDownload)
                let fileExists = FileManager.default.fileExists(atPath: url.path)
                XCTAssertTrue(fileExists, "Downloaded file doesn't exist")
                let httpResponse = response as? HTTPURLResponse
                XCTAssertNotNil(httpResponse)
                XCTAssertEqual(httpResponse?.statusCode, 200)
                let (newUrl, _) = try await provider.download(.fileDownload)
                let newFileExists = FileManager.default.fileExists(atPath: newUrl.path)
                XCTAssertTrue(newFileExists, "Redownloaded file doesn't exist")
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error.localizedDescription)")
            }
        }

        wait(for: [expectation], timeout: 20)
    }

    func testDownloadStatus() throws {
        let expectation = XCTestExpectation(description: "I can follow download status")
        expectation.expectedFulfillmentCount = 4

        let failExpectation = XCTestExpectation(description: "Task doesn't fail")
        failExpectation.isInverted = true

        let provider = ArachneProvider<MyService>(urlSession: session)
        Task {
            do {
                _ = try await provider.download(.fileDownload) { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                    XCTAssertLessThanOrEqual(bytesWritten, totalBytesWritten, "Bytes written are more than total bytes written")
                    expectation.fulfill()
                } didCompleteTask: { result in
                    switch result {
                    case .success((let url, let response)):
                        XCTAssertNotNil(url)
                        XCTAssertNotNil(response)
                        let fileExists = FileManager.default.fileExists(atPath: url.path)
                        XCTAssertTrue(fileExists, "Downloaded file doesn't exist")
                        let httpResponse = response as? HTTPURLResponse
                        XCTAssertNotNil(httpResponse)
                        XCTAssertEqual(httpResponse?.statusCode, 200)
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail("Unexpected error: \(error.localizedDescription)")
                        failExpectation.fulfill()
                    }
                }
                _ = try await provider.download(.fileDownload) { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                    XCTAssertLessThanOrEqual(bytesWritten, totalBytesWritten, "Bytes written are more than total bytes written")
                    expectation.fulfill()
                } didCompleteTask: { result in
                    switch result {
                    case .success((let url, let response)):
                        XCTAssertNotNil(url)
                        XCTAssertNotNil(response)
                        let fileExists = FileManager.default.fileExists(atPath: url.path)
                        XCTAssertTrue(fileExists, "Downloaded file doesn't exist")
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail("Unexpected error: \(error.localizedDescription)")
                        failExpectation.fulfill()
                    }
                }
            }
        }

        wait(for: [expectation, failExpectation], timeout: timeout)
    }

    func testCancelAndResumeDownload() throws {
        let expectation = XCTestExpectation(description: "I can cancel and resume a download")
        expectation.expectedFulfillmentCount = 3

        let failExpectation = XCTestExpectation(description: "Task doesn't fail")
        failExpectation.isInverted = true

        let provider = ArachneProvider<MyService>(urlSession: session)
        Task {
            let task = try await provider.download(.fileDownload) { _, _, _ in
                // Nothing to do
            } didCompleteTask: { _ in
                failExpectation.fulfill()
            }

            guard let data = await task.cancelByProducingResumeData() else {
                return failExpectation.fulfill()
            }

            _ = try await provider.download(.fileDownload, withResumeData: data) { fileOffset, expectedTotalBytes in
                expectation.fulfill()
            } didWriteData: { _, _, _ in
                expectation.fulfill()
            } didCompleteTask: { result in
                switch result {
                case .success((let url, let response)):
                    XCTAssertNotNil(url)
                    XCTAssertNotNil(response)
                    let fileExists = FileManager.default.fileExists(atPath: url.path)
                    XCTAssertTrue(fileExists, "Downloaded file doesn't exist")
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail("Unexpected error: \(error.localizedDescription)")
                    failExpectation.fulfill()
                }
            }
        }

    }

    func testResponseHasUnacceptableStatusCode() throws {
        let expectation = XCTestExpectation(description: "Request returns an unacceptable status code")

        let provider = ArachneProvider<MyServiceWithDefaults>(urlSession: session)
        Task {
            do {
                _ = try await provider.data(.notFound)
                XCTFail("Shouldn't receive any value, status code should be unacceptable")
            } catch let error as ARError {
                switch error {
                case .unacceptableStatusCode(_, let response, let data):
                    let expectedError = ARError.unacceptableStatusCode(statusCode: 404,
                                                                       response: HTTPURLResponse(),
                                                                       responseContent: Data())
                    XCTAssertEqual(error.errorCode, expectedError.errorCode)
                    XCTAssertNotNil(response)
                    XCTAssertNotNil(data)
                    XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                    expectation.fulfill()
                case .unexpectedMimeType, .missingData:
                    XCTFail("This is not the error you are looking for")
                }
            } catch {
                XCTFail("Shouldn't receive any other error")
            }
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testDownloadHasUnacceptableStatusCode() throws {
        let expectation = XCTestExpectation(description: "Request returns an unacceptable status code")

        let provider = ArachneProvider<MyServiceWithDefaults>(urlSession: session)
        Task {
            do {
                _ = try await provider.download(.notFound)
                XCTFail("Shouldn't receive any value, status code should be unacceptable")
            } catch let error as ARError {
                switch error {
                case .unacceptableStatusCode(let statusCode, let response, let data):
                    let expectedError = ARError.unacceptableStatusCode(statusCode: 404,
                                                                       response: HTTPURLResponse(),
                                                                       responseContent: Data())
                    XCTAssertEqual(error.errorCode, expectedError.errorCode)
                    XCTAssertEqual(statusCode, 404)
                    XCTAssertNotNil(response)
                    XCTAssertNotNil(data)
                    XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                    expectation.fulfill()
                case .unexpectedMimeType, .missingData:
                    XCTFail("This is not the error you are looking for")
                }
            } catch {
                XCTFail("Shouldn't receive any other error")
            }
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testResponseHasUnexpectedMimeType() throws {
        let expectation = XCTestExpectation(description: "Response has unexpected mime type")

        let provider = ArachneProvider<MyService>(urlSession: session)
        Task {
            do {
                _ = try await provider.download(.unexpectedMimeType)
                XCTFail("Shouldn't receive any value, mime type should mismatch")
            } catch let error as ARError {
                switch error {
                case .unexpectedMimeType(let mimeType, _, _):
                    let expectedError = ARError.unexpectedMimeType(mimeType: "text/plain",
                                                                   response: HTTPURLResponse(),
                                                                   responseContent: Data())
                    XCTAssertEqual(error.errorCode, expectedError.errorCode)
                    XCTAssertEqual(mimeType, "text/plain")
                    XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                    expectation.fulfill()
                case .unacceptableStatusCode, .missingData:
                    XCTFail("This is not the error you are looking for")
                }
            } catch {
                XCTFail("Shouldn't receive any other error")
            }
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testPluginHasErrorResponse() throws {
        struct TestPlugin: ArachnePlugin {
            let errorExpectation: XCTestExpectation
            let requestExpectation: XCTestExpectation

            func handle(error: Error, request: URLRequest, output: Any?) {
                XCTAssertEqual(request.url?.absoluteString,
                               try? MyServiceWithDefaults.notFound.url().absoluteString,
                               "Request URL in error is not equal to expected URL")
                XCTAssertNotNil(output)
                errorExpectation.fulfill()
            }

            func handle(request: URLRequest) {
                XCTAssertEqual(request.url?.absoluteString, try MyServiceWithDefaults.notFound.url().absoluteString)
                requestExpectation.fulfill()
            }

            func handle(response: URLResponse, data: Any) {
                XCTFail("Should not have been called")
            }
        }

        let errorExpectation = XCTestExpectation(description: "The plugin has correct error response data")
        let requestExpectation = XCTestExpectation(description: "The plugin handles the correct request")
        let plugin = TestPlugin(errorExpectation: errorExpectation, requestExpectation: requestExpectation)

        let provider = ArachneProvider<MyServiceWithDefaults>(urlSession: session).with(plugins: [plugin])
        Task {
            do {
                _ = try await provider.data(.notFound)
                XCTFail("Shouldn't receive any value, status code should be unacceptable")
            } catch {
                // Nothing to do
            }
        }

        wait(for: [errorExpectation, requestExpectation], timeout: timeout)
    }

    func testRequestModifier() throws {
        let requestModifier: (MyService, inout URLRequest) async throws -> Void = { _, request in
            let url = request.url?.absoluteString ?? ""
            request.url = URL(string: "\(url)modified")
        }
        let expectation = XCTestExpectation(
            description: "Request is modified by the signingPublisher and returns a valid user")

        let provider = ArachneProvider<MyService>(urlSession: session).with(requestModifier: requestModifier)
        Task {
            do {
                let modifiedRequest = try await provider.finalRequest(target: .jsonResponse)
                XCTAssertEqual(modifiedRequest.url, URL(string: "\(try MyService.jsonResponse.url())modified"), "URL was not modified")
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error.localizedDescription)")
            }
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testInit() throws {
        class TestURLSessionDelegate: NSObject, URLSessionDataDelegate {
            var check: Bool

            override init() {
                self.check = false
            }

            func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
                check = true
            }

            func reset() {
                check = false
            }
        }

        let expectation = XCTestExpectation(description: "The provider is using my URLSession")

        Task {
            do {
                let delegate = TestURLSessionDelegate()
                let customUrlSession = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
                var provider = ArachneProvider<MyService>(urlSession: customUrlSession)
                _ = try await provider.data(.plainText)
                XCTAssertTrue(delegate.check)

                delegate.reset()

                provider = provider.with(plugins: [])
                _ = try await provider.data(.plainText)
                XCTAssertTrue(delegate.check)

                delegate.reset()

                provider = provider.with(requestModifier: { _, _ in })
                _ = try await provider.data(.plainText)
                XCTAssertTrue(delegate.check)

                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error.localizedDescription)")
            }
        }

        wait(for: [expectation], timeout: timeout)
    }
}
