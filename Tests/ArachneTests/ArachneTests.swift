import XCTest
import Combine
@testable import Arachne

final class ArachneTests: XCTestCase {
    let timeout: TimeInterval = 10
    var cancellable: AnyCancellable?

    func testGet() throws {
        let expectation = XCTestExpectation(description: "Download my Github user info")

        let provider = ArachneProvider<Github>()
        cancellable = provider.request(.userProfile("artemisia-absynthium"))
            .decode(type: GithubUser.self, decoder: JSONDecoder())
            .sink { _ in } receiveValue: { user in
                XCTAssertEqual(user, GithubUser(login: "artemisia-absynthium"))
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: timeout)
    }

    override func tearDown() {
        super.tearDown()
        cancellable = nil
    }

    func testMalformedUrlErrorBecauseOfBaseUrl() throws {
        let expectation = XCTestExpectation(description: "Service URL is malformed")

        let provider = ArachneProvider<Dummy>()
        cancellable = provider.request(.malformedUrl)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    let castedError = error as? ARError
                    let expectedError = ARError.malformedUrl("htp:🥶/malformedUrl")
                    XCTAssertNotNil(castedError)
                    XCTAssertEqual(castedError?.errorCode, expectedError.errorCode)
                    XCTAssertEqual(castedError?.localizedDescription, expectedError.localizedDescription)
                    expectation.fulfill()
                case .finished:
                    XCTFail("Request shouldn't have finished, URL should be malformed")
                }
            }, receiveValue: { _ in
                XCTFail("Shouldn't receive any value, URL is malformed")
            })

        wait(for: [expectation], timeout: timeout)
    }

    func testMalformedUrlErrorBecauseOfPath() throws {
        let expectation = XCTestExpectation(description: "Endpoint path is malformed")

        let provider = ArachneProvider<Dummy>()
        cancellable = provider.request(.nilUrl)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    let castedError = error as? ARError
                    var urlComponents = URLComponents(string: "https://malformedquerystring.io")
                    let endpoint = Dummy.nilUrl
                    urlComponents?.path = endpoint.path
                    urlComponents?.queryItems = endpoint.queryStringItems
                    let expectedError = ARError.malformedUrl(urlComponents?.description ?? "")
                    XCTAssertNotNil(castedError)
                    XCTAssertEqual(castedError?.errorCode, expectedError.errorCode)
                    XCTAssertEqual(castedError?.localizedDescription, expectedError.localizedDescription)
                    expectation.fulfill()
                case .finished:
                    XCTFail("Request shouldn't have finished, URL should be malformed")
                }
            }, receiveValue: { _ in
                XCTFail("Shouldn't receive any value, URL is malformed")
            })

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
        cancellable = provider.download(.avatar(id))
            .sink { _ in } receiveValue: { url, response in
                let fileExists = FileManager.default.fileExists(atPath: url.path)
                XCTAssertTrue(fileExists, "Downloaded file doesn't exist")
                let httpResponse = response as? HTTPURLResponse
                XCTAssertNotNil(httpResponse)
                XCTAssertEqual(httpResponse?.statusCode, 200)
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 20)
    }

    func testRequestUnacceptableStatusCodeError() throws {
        let expectation = XCTestExpectation(description: "Request returns an unacceptable status code")

        let provider = ArachneProvider<Github>()
        cancellable = provider.request(.notFound)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    let castedError = error as? ARError
                    switch castedError {
                    case .malformedUrl:
                        XCTFail("Error shouldn't be malformed URL")
                    case .unacceptableStatusCode(let statusCode, let response, let data):
                        let expectedError = ARError.unacceptableStatusCode(statusCode: 404,
                                                                           response: HTTPURLResponse(),
                                                                           responseContent: Data())
                        XCTAssertNotNil(castedError)
                        XCTAssertEqual(castedError?.errorCode, expectedError.errorCode)
                        XCTAssertEqual(statusCode, 404)
                        XCTAssertNotNil(response)
                        XCTAssertNotNil(data)
                        XCTAssertEqual(castedError?.localizedDescription, expectedError.localizedDescription)
                        expectation.fulfill()
                    case .none:
                        XCTFail("Error shouldn't be none")
                    }
                case .finished:
                    XCTFail("Request shouldn't have finished, status code should be unacceptable")
                }
            }, receiveValue: { _ in
                XCTFail("Shouldn't receive any value, status code should be unacceptable")
            })

        wait(for: [expectation], timeout: timeout)
    }

    func testDownloadUnacceptableStatusCodeError() throws {
        let expectation = XCTestExpectation(description: "Request returns an unacceptable status code")

        let provider = ArachneProvider<Github>()
        cancellable = provider.download(.notFound)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    let castedError = error as? ARError
                    switch castedError {
                    case .malformedUrl:
                        XCTFail("Error shouldn't be malformed URL")
                    case .unacceptableStatusCode(let statusCode, let response, let data):
                        let expectedError = ARError.unacceptableStatusCode(statusCode: 404,
                                                                           response: HTTPURLResponse(),
                                                                           responseContent: Data())
                        XCTAssertNotNil(castedError)
                        XCTAssertEqual(castedError?.errorCode, expectedError.errorCode)
                        XCTAssertEqual(statusCode, 404)
                        XCTAssertNotNil(response)
                        XCTAssertNotNil(data)
                        XCTAssertEqual(castedError?.localizedDescription, expectedError.localizedDescription)
                        expectation.fulfill()
                    case .none:
                        XCTFail("Error shouldn't be none")
                    }
                case .finished:
                    XCTFail("Request shouldn't have finished, status code should be unacceptable")
                }
            }, receiveValue: { _ in
                XCTFail("Shouldn't receive any value, status code should be unacceptable")
            })

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
        cancellable = provider.request(.notFound)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in
                XCTFail("Shouldn't receive any value, status code should be unacceptable")
            })

        wait(for: [errorExpectation, requestExpectation], timeout: 10)
    }

    func testSigningPublisher() throws {
        let signingPublisher: (Github, URLRequest) -> AnyPublisher<URLRequest, URLError> = { _, request in
            var mutableRequest = request
            var url = request.url?.absoluteString ?? ""
            url += "artemisia-absynthium"
            mutableRequest.url = URL(string: url)
            return Just(mutableRequest)
                .setFailureType(to: URLError.self)
                .eraseToAnyPublisher()
        }
        let expectation = XCTestExpectation(
            description: "Request is modified by the signingPublisher and returns a valid user")

        let provider = ArachneProvider<Github>(signingPublisher: signingPublisher)
        cancellable = provider.request(.userProfile(""))
            .decode(type: GithubUser.self, decoder: JSONDecoder())
            .sink { _ in } receiveValue: { user in
                XCTAssertEqual(user, GithubUser(login: "artemisia-absynthium"))
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: timeout)
    }
}
