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
    let timeout: TimeInterval = 10

    func testGet() throws {
        let expectation = XCTestExpectation(description: "Download my Github user info")

        let provider = ArachneProvider<Github>()
        Task {
            do {
                let (data, _) = try await provider.data(.userProfile("artemisia-absynthium"))
                let user = try JSONDecoder().decode(GithubUser.self, from: data)
                XCTAssertEqual(user, GithubUser(login: "artemisia-absynthium"))
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error.localizedDescription)")
            }
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testMalformedUrlErrorBecauseOfBaseUrl() throws {
        let expectation = XCTestExpectation(description: "Service URL is malformed")

        let provider = ArachneProvider<Dummy>()
        Task {
            do {
                _ = try await provider.data(.malformedUrl)
                XCTFail("Shouldn't receive any value, URL is malformed")
            } catch let error as ARError {
                let expectedError = ARError.malformedUrl("htp:🥶/malformedUrl")
                XCTAssertEqual(error.errorCode, expectedError.errorCode)
                XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                expectation.fulfill()
            } catch {
                XCTFail("Shouldn't receive any other error")
            }
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testMalformedUrlErrorBecauseOfPath() throws {
        let expectation = XCTestExpectation(description: "Endpoint path is malformed")

        let provider = ArachneProvider<Dummy>()
        Task {
            do {
                _ = try await provider.data(.nilUrl)
                XCTFail("Shouldn't receive any value, URL is malformed")
            } catch let error as ARError {
                var urlComponents = URLComponents(string: "https://malformedquerystring.io")
                let endpoint = Dummy.nilUrl
                urlComponents?.path = endpoint.path
                urlComponents?.queryItems = endpoint.queryStringItems
                let expectedError = ARError.malformedUrl(urlComponents?.description ?? "")
                XCTAssertEqual(error.errorCode, expectedError.errorCode)
                XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                expectation.fulfill()
            } catch {
                XCTFail("Shouldn't receive any other error")
            }
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testReservedAppleHeaderIsNotAdded() throws {
        let endpoint = Dummy.reservedHeader

        let provider = ArachneProvider<Dummy>()
        do {
            let builtRequest = try provider.buildRequest(target: endpoint, timeoutInterval: timeout)
            XCTAssertNil(builtRequest.value(forHTTPHeaderField: "Content-Length"))
        } catch {
            XCTFail("Building request for endpoint \(endpoint) should not fail")
        }
    }

    func testPost() throws {
        let endpoint = Dummy.postSomething

        let provider = ArachneProvider<Dummy>()
        do {
            let builtRequest = try provider.buildRequest(target: endpoint, timeoutInterval: timeout)
            XCTAssertEqual(builtRequest.httpBody, "I'm posting something".data(using: .utf8))
        } catch {
            XCTFail("Building request for endpoint \(endpoint) should not fail")
        }
    }

    func testDownload() throws {
        let id = "7290872"

        let expectation = XCTestExpectation(description: "Download an image")

        let provider = ArachneProvider<Github>()
        Task {
            do {
                let (url, response) = try await provider.download(.avatar(id))
                let fileExists = FileManager.default.fileExists(atPath: url.path)
                XCTAssertTrue(fileExists, "Downloaded file doesn't exist")
                let httpResponse = response as? HTTPURLResponse
                XCTAssertNotNil(httpResponse)
                XCTAssertEqual(httpResponse?.statusCode, 200)
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error.localizedDescription)")
            }
        }

        wait(for: [expectation], timeout: 20)
    }

    func testRequestUnacceptableStatusCodeError() throws {
        let expectation = XCTestExpectation(description: "Request returns an unacceptable status code")

        let provider = ArachneProvider<Github>()
        Task {
            do {
                _ = try await provider.data(.notFound)
                XCTFail("Shouldn't receive any value, status code should be unacceptable")
            } catch let error as ARError {
                switch error {
                case .malformedUrl:
                    XCTFail("Error shouldn't be malformed URL")
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
                }
            } catch {
                XCTFail("Shouldn't receive any other error")
            }
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testDownloadUnacceptableStatusCodeError() throws {
        let expectation = XCTestExpectation(description: "Request returns an unacceptable status code")

        let provider = ArachneProvider<Github>()
        Task {
            do {
                _ = try await provider.download(.notFound)
                XCTFail("Shouldn't receive any value, status code should be unacceptable")
            } catch let error as ARError {
                switch error {
                case .malformedUrl:
                    XCTFail("Error shouldn't be malformed URL")
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
                               "https://api.github.com/notFound",
                               "Request URL in error is not equal to expected URL")
                XCTAssertTrue(error is ARError)
                switch error as? ARError {
                case .some(.unacceptableStatusCode(let statusCode, _, _)):
                    XCTAssertEqual(statusCode, 404)
                case .none:
                    XCTFail("Error is none but should be unacceptableStatusCode")
                case .some(.malformedUrl(_)):
                    XCTFail("Error is malformedUrl but should be unacceptableStatusCode")
                }
                XCTAssertNotNil(output)
                errorExpectation.fulfill()
            }

            func handle(request: URLRequest) {
                XCTAssertEqual(request.url?.absoluteString, "\(Github.notFound.baseUrl)\(Github.notFound.path)")
                requestExpectation.fulfill()
            }

            func handle(response: URLResponse, data: Any) {
                XCTFail("Should not have been called")
            }
        }

        let errorExpectation = XCTestExpectation(description: "The plugin has correct error response data")
        let requestExpectation = XCTestExpectation(description: "The plugin handles the correct request")
        let plugin = TestPlugin(errorExpectation: errorExpectation, requestExpectation: requestExpectation)

        let provider = ArachneProvider<Github>(plugins: [plugin])
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

    func testSigningFunction() throws {
        let signingFunction: (Github, URLRequest) async throws -> URLRequest = { _, request in
            var mutableRequest = request
            var url = request.url?.absoluteString ?? ""
            url += "artemisia-absynthium"
            mutableRequest.url = URL(string: url)
            return mutableRequest
        }
        let expectation = XCTestExpectation(
            description: "Request is modified by the signingPublisher and returns a valid user")

        let provider = ArachneProvider<Github>(signingFunction: signingFunction, plugins: nil)
        Task {
            do {
                let (data, _) = try await provider.data(.userProfile(""))
                let user = try JSONDecoder().decode(GithubUser.self, from: data)
                XCTAssertEqual(user, GithubUser(login: "artemisia-absynthium"))
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error.localizedDescription)")
            }
        }

        wait(for: [expectation], timeout: timeout)
    }
}
