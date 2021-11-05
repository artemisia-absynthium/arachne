import XCTest
import Combine
@testable import Arachne

final class ArachneTests: XCTestCase {

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

        wait(for: [expectation], timeout: 5)
    }

    override func tearDown() {
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

        wait(for: [expectation], timeout: 5)
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

        wait(for: [expectation], timeout: 5)
    }

    func testReservedAppleHeaderIsNotAdded() throws {
        let endpoint = Dummy.reservedHeader

        let provider = ArachneProvider<Dummy>()
        do {
            let builtRequest = try provider.buildRequest(target: endpoint, timeoutInterval: 5)
            XCTAssertNil(builtRequest.value(forHTTPHeaderField: "Content-Length"))
        } catch {
            XCTFail("Building request for endpoint \(endpoint) should not fail")
        }
    }

    func testPost() throws {
        let endpoint = Dummy.postSomething

        let provider = ArachneProvider<Dummy>()
        do {
            let builtRequest = try provider.buildRequest(target: endpoint, timeoutInterval: 5)
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

        wait(for: [expectation], timeout: 5)
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
                    case .unacceptableStatusCode(let statusCode, let data):
                        let expectedError = ARError.unacceptableStatusCode(404, Data())
                        XCTAssertNotNil(castedError)
                        XCTAssertEqual(castedError?.errorCode, expectedError.errorCode)
                        XCTAssertEqual(statusCode, 404)
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

        wait(for: [expectation], timeout: 5)
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
                    case .unacceptableStatusCode(let statusCode, let data):
                        let expectedError = ARError.unacceptableStatusCode(404, Data())
                        XCTAssertNotNil(castedError)
                        XCTAssertEqual(castedError?.errorCode, expectedError.errorCode)
                        XCTAssertEqual(statusCode, 404)
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

        wait(for: [expectation], timeout: 5)
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
        let expectation = XCTestExpectation(description: "Request is modified by the signingPublisher and returns a valid user")

        let provider = ArachneProvider<Github>(signingPublisher: signingPublisher)
        cancellable = provider.request(.userProfile(""))
            .decode(type: GithubUser.self, decoder: JSONDecoder())
            .sink { _ in } receiveValue: { user in
                XCTAssertEqual(user, GithubUser(login: "artemisia-absynthium"))
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 5)
    }
    
}
