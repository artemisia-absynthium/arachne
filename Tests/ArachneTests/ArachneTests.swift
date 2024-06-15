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
        configuration.protocolClasses = [StubURLProtocol.self]
        return configuration
    }()
    lazy var session: URLSession = URLSession(configuration: configuration)

    override class func setUp() {
        URLProtocol.registerClass(StubURLProtocol.self)
        let service1Exchanges: [StubNetworkExchange] = MyService.allCases
            .compactMap { guard let request = try? $0.urlRequest() else { return nil }
                return StubNetworkExchange(urlRequest: request, response: $0.stubResponse) }
        let service2Exchanges: [StubNetworkExchange] = MyServiceWithDefaults.allCases
            .compactMap { guard let request = try? $0.urlRequest() else { return nil }
                return StubNetworkExchange(urlRequest: request, response: $0.stubResponse) }
        StubURLProtocol.stubExchanges = Set(service1Exchanges + service2Exchanges)
    }

    override class func tearDown() {
        URLProtocol.unregisterClass(StubURLProtocol.self)
    }

    func testGet() throws {
        let expectation = XCTestExpectation(description: "Get request returns expected JSON data")
        let expectedModel = MyModel(field: "field")

        let provider = ArachneProvider<MyService>(urlSession: session)
        Task {
            do {
                let (data, _) = try await provider.data(.jsonResponse)
                let model = try JSONDecoder().decode(MyModel.self, from: data)
                XCTAssertEqual(model, expectedModel)
            } catch {
                XCTFail("Unexpected error: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testMalformedUrlError() throws {
        let expectation = XCTestExpectation(description: "Endpoint path is malformed")
        let expectedError = URLError(.unsupportedURL)

        let provider = ArachneProvider<MyServiceWithDefaults>(urlSession: session)
        Task {
            do {
                _ = try await provider.data(.nilUrl)
                XCTFail("Shouldn't receive any value, URL is malformed")
            } catch let error as URLError {
                XCTAssertEqual(error.errorCode, expectedError.errorCode)
            } catch {
                XCTFail("Shouldn't receive any other error")
            }
            expectation.fulfill()
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
 
        let builtRequest = try MyServiceWithDefaults.postSomething.urlRequest()
        XCTAssertEqual(builtRequest.httpBody, "I'm posting something".data(using: .utf8))
        
        let provider = ArachneProvider<MyServiceWithDefaults>(urlSession: session)
        Task {
            do {
                _ = try await provider.data(.postSomething)
            } catch {
                XCTFail("Unexpected error: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testDownloadTwice() throws {
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
            } catch {
                XCTFail("Unexpected error: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testDownloadStatusTwice() throws {
        let writeDataExpectation = XCTestExpectation(description: "Data write is reported")
        writeDataExpectation.expectedFulfillmentCount = 2
        
        let completeDownloadExpectation = XCTestExpectation(description: "Download is complete")
        completeDownloadExpectation.expectedFulfillmentCount = 2

        let provider = ArachneProvider<MyService>(urlSession: session)
        Task {
            do {
                _ = try await provider.download(.fileDownload) { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                    XCTAssertLessThanOrEqual(bytesWritten, totalBytesWritten, "Bytes written are more than total bytes written")
                    writeDataExpectation.fulfill()
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
                    case .failure(let error):
                        XCTFail("Unexpected error: \(error.localizedDescription)")
                    }
                    completeDownloadExpectation.fulfill()
                }
                _ = try await provider.download(.fileDownload) { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                    XCTAssertLessThanOrEqual(bytesWritten, totalBytesWritten, "Bytes written are more than total bytes written")
                    writeDataExpectation.fulfill()
                } didCompleteTask: { result in
                    switch result {
                    case .success((let url, let response)):
                        XCTAssertNotNil(url)
                        XCTAssertNotNil(response)
                        let fileExists = FileManager.default.fileExists(atPath: url.path)
                        XCTAssertTrue(fileExists, "Downloaded file doesn't exist")
                    case .failure(let error):
                        XCTFail("Unexpected error: \(error.localizedDescription)")
                    }
                    completeDownloadExpectation.fulfill()
                }
            }
        }

        wait(for: [completeDownloadExpectation, writeDataExpectation], timeout: timeout)
    }

    func testResponseHasUnacceptableStatusCode() throws {
        let expectation = XCTestExpectation(description: "Request returns an unacceptable status code")
        let expectedError = ARError.unacceptableStatusCode(statusCode: 404,
                                                           response: HTTPURLResponse(),
                                                           responseContent: Data())

        let provider = ArachneProvider<MyServiceWithDefaults>(urlSession: session)
        Task {
            do {
                _ = try await provider.data(.notFound)
                XCTFail("Shouldn't receive any value, status code should be unacceptable")
            } catch let error as ARError {
                switch error {
                case .unacceptableStatusCode(_, let response, let data):
                    XCTAssertEqual(error.errorCode, expectedError.errorCode)
                    XCTAssertNotNil(response)
                    XCTAssertNotNil(data)
                    XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                case .unexpectedMimeType, .missingData:
                    XCTFail("This is not the error you are looking for")
                }
            } catch {
                XCTFail("Shouldn't receive any other error")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testDownloadHasUnacceptableStatusCode() throws {
        let expectation = XCTestExpectation(description: "Request returns an unacceptable status code")
        let expectedError = ARError.unacceptableStatusCode(statusCode: 404,
                                                           response: HTTPURLResponse(),
                                                           responseContent: Data())

        let provider = ArachneProvider<MyServiceWithDefaults>(urlSession: session)
        Task {
            do {
                _ = try await provider.download(.notFound)
                XCTFail("Shouldn't receive any value, status code should be unacceptable")
            } catch let error as ARError {
                switch error {
                case .unacceptableStatusCode(let statusCode, let response, let data):
                    XCTAssertEqual(error.errorCode, expectedError.errorCode)
                    XCTAssertEqual(statusCode, 404)
                    XCTAssertNotNil(response)
                    XCTAssertNotNil(data)
                    XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                case .unexpectedMimeType, .missingData:
                    XCTFail("This is not the error you are looking for")
                }
            } catch {
                XCTFail("Shouldn't receive any other error")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testResponseHasUnexpectedMimeType() throws {
        let expectation = XCTestExpectation(description: "Response has unexpected mime type")
        let expectedError = ARError.unexpectedMimeType(mimeType: "text/plain",
                                                       response: HTTPURLResponse(),
                                                       responseContent: Data())

        let provider = ArachneProvider<MyService>(urlSession: session)
        Task {
            do {
                _ = try await provider.download(.unexpectedMimeType)
                XCTFail("Shouldn't receive any value, mime type should mismatch")
            } catch let error as ARError {
                switch error {
                case .unexpectedMimeType(let mimeType, _, _):
                    XCTAssertEqual(error.errorCode, expectedError.errorCode)
                    XCTAssertEqual(mimeType, "text/plain")
                    XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                case .unacceptableStatusCode, .missingData:
                    XCTFail("This is not the error you are looking for")
                }
            } catch {
                XCTFail("Shouldn't receive any other error")
            }
            expectation.fulfill()
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
                errorExpectation.fulfill()
                requestExpectation.fulfill()
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
                let modifiedRequest = try await provider.urlRequest(for: .jsonResponse)
                XCTAssertEqual(modifiedRequest.url, URL(string: "\(try MyService.jsonResponse.url())modified"), "URL was not modified")
            } catch {
                XCTFail("Unexpected error: \(error.localizedDescription)")
            }
            expectation.fulfill()
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
            } catch {
                XCTFail("Unexpected error: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }
}
