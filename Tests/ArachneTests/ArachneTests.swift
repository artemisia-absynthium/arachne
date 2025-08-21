//
// ArachneTests.swift - test suite
// This source file is part of the Arachne open source project
//
// Copyright (c) 2021 - 2025 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Testing
import Foundation
@testable import Arachne

@Suite("Arachne Tests")
class ArachneTests {
    let timeout: TimeInterval = 10
    lazy var configuration: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return configuration
    }()
    lazy var session: URLSession = URLSession(configuration: configuration)

    init() {
        URLProtocol.registerClass(StubURLProtocol.self)
        let service1Exchanges: [StubNetworkExchange] = MyService.allCases
            .compactMap { guard let request = try? $0.urlRequest() else { return nil }
                return StubNetworkExchange(urlRequest: request, response: $0.stubResponse) }
        let service2Exchanges: [StubNetworkExchange] = MyServiceWithDefaults.allCases
            .compactMap { guard let request = try? $0.urlRequest() else { return nil }
                return StubNetworkExchange(urlRequest: request, response: $0.stubResponse) }
        StubURLProtocol.stubExchanges = Set(service1Exchanges + service2Exchanges)
    }

    deinit {
        URLProtocol.unregisterClass(StubURLProtocol.self)
    }

    @Test("Get request returns expected JSON data")
    func testGet() async throws {
        let expectedModel = MyModel(field: "field")

        let provider = ArachneProvider<MyService>(urlSession: session)
        let (data, _) = try await provider.data(.jsonResponse)
        let model = try JSONDecoder().decode(MyModel.self, from: data)
        try #require(model == expectedModel)
    }

    @Test("Endpoint path is malformed")
    func testMalformedUrlError() async throws {
        let expectedError = URLError(.unsupportedURL)

        let provider = ArachneProvider<MyServiceWithDefaults>(urlSession: session)
        do {
            _ = try await provider.data(.nilUrl)
            Issue.record("Shouldn't receive any value, URL is malformed")
        } catch let error as URLError {
            try #require(error.errorCode == expectedError.errorCode)
        } catch {
            Issue.record("Shouldn't receive any other error")
        }
    }

    @Test("Reserved Apple header is not added")
    func testReservedAppleHeaderIsNotAdded() throws {
        let endpoint = MyServiceWithDefaults.reservedHeader

        let builtRequest = try endpoint.urlRequest()
        try #require(builtRequest.value(forHTTPHeaderField: "Content-Length") == nil)
    }

    @Test("POST request gets executed fine and body is as expected")
    func testPost() async throws {
        let builtRequest = try MyServiceWithDefaults.postSomething.urlRequest()
        try #require(builtRequest.httpBody == Data("I'm posting something".utf8))

        let provider = ArachneProvider<MyServiceWithDefaults>(urlSession: session)
        _ = try await provider.data(.postSomething)
    }

    @Test("Download an image")
    func testDownloadTwice() async throws {
        let provider = ArachneProvider<MyService>(urlSession: session)
        let (url, response) = try await provider.download(.fileDownload)
        let fileExists = FileManager.default.fileExists(atPath: url.path)
        try #require(fileExists, "Downloaded file doesn't exist")
        let httpResponse = response as? HTTPURLResponse
        try #require(httpResponse != nil)
        try #require(httpResponse?.statusCode == 200)
        let (newUrl, _) = try await provider.download(.fileDownload)
        let newFileExists = FileManager.default.fileExists(atPath: newUrl.path)
        try #require(newFileExists, "Redownloaded file doesn't exist")
    }

    @Test("Download status is reported correctly")
    @MainActor func testDownloadStatusTwice() async throws {
        let provider = ArachneProvider<MyService>(urlSession: session)

        try await confirmation(expectedCount: 4...) { statusReported in
            let task1 = try await provider.download(.fileDownload) { bytesWritten, totalBytesWritten, _ in
                #expect(bytesWritten <= totalBytesWritten, "Bytes written are more than total bytes written")
                statusReported()
            } didCompleteTask: { url, response in
                let fileExists = FileManager.default.fileExists(atPath: url.path)
                #expect(fileExists, "Downloaded file doesn't exist")
                let httpResponse = response as? HTTPURLResponse
                #expect(httpResponse != nil)
                #expect(httpResponse?.statusCode == 200)
                statusReported()
            } didFailTask: { error in
                Issue.record("Unexpected error: \(error.localizedDescription)")
            }

            let task2 = try await provider.download(.fileDownload) { bytesWritten, totalBytesWritten, _ in
                #expect(bytesWritten <= totalBytesWritten, "Bytes written are more than total bytes written")
                statusReported()
            } didCompleteTask: { url, _ in
                let fileExists = FileManager.default.fileExists(atPath: url.path)
                #expect(fileExists, "Downloaded file doesn't exist")
                statusReported()
            } didFailTask: { error in
                Issue.record("Unexpected error: \(error.localizedDescription)")
            }

            while task1.state == .running || task2.state == .running {
                continue
            }
        }
    }

    @Test("I can download bytes")
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    func testBytes() async throws {
        let provider = ArachneProvider<MyService>(urlSession: session)
        var count = 0
        let (bytes, response) = try await provider.bytes(.fileDownload)
        for try await _ in bytes {
            count += 1
        }
        let httpUrlResponse = response as? HTTPURLResponse
        try #require(httpUrlResponse != nil)
        try #require(httpUrlResponse?.statusCode == 200)
        try #require(count == 114521, "Unexpected number of bytes")
    }

    @Test("I can upload data")
    func testUploadData() async throws {
        let provider = ArachneProvider<MyService>(urlSession: session)
        let (data, response) = try await provider.upload(.plainText, from: sampleImageData)
        try #require(data == Data("The response is 42".utf8), "Data is different than expected")
        let httpResponse = response as? HTTPURLResponse
        try #require(httpResponse != nil, "Response is not HTTPURLResponse")
        try #require(httpResponse?.statusCode == 200, "Status code is different than expected")
    }

    @Test("I can upload file")
    func testUploadFile() async throws {
        let provider = ArachneProvider<MyService>(urlSession: session)
        let (data, response) = try await provider.upload(.plainText, fromFile: sampleImageUrl)
        try #require(data == Data("The response is 42".utf8), "Data is different than expected")
        let httpResponse = response as? HTTPURLResponse
        try #require(httpResponse != nil, "Response is not HTTPURLResponse")
        try #require(httpResponse?.statusCode == 200, "Status code is different than expected")
    }
}

extension ArachneTests {
    @Test("Request returns an unacceptable status code")
    func testResponseHasUnacceptableStatusCode() async throws {
        let expectedError = ARError.unacceptableStatusCode(statusCode: 404,
                                                           response: HTTPURLResponse(),
                                                           responseContent: .data(Data()))

        let provider = ArachneProvider<MyServiceWithDefaults>(urlSession: session)
        do {
            _ = try await provider.data(.notFound)
            Issue.record("Shouldn't receive any value, status code should be unacceptable")
        } catch let error as ARError {
            switch error {
            case .unacceptableStatusCode(_, let response, _):
                try #require(error.errorCode == expectedError.errorCode)
                try #require(response != nil)
                try #require(error.localizedDescription == expectedError.localizedDescription)
            case .unexpectedMimeType, .missingData:
                Issue.record("This is not the error you are looking for")
            }
        } catch {
            Issue.record("Shouldn't receive any other error")
        }
    }

    @Test("Download request returns an unacceptable status code")
    func testDownloadHasUnacceptableStatusCode() async throws {
        let expectedError = ARError.unacceptableStatusCode(statusCode: 404,
                                                           response: HTTPURLResponse(),
                                                           responseContent: .data(Data()))

        let provider = ArachneProvider<MyServiceWithDefaults>(urlSession: session)
        do {
            _ = try await provider.download(.notFound)
            Issue.record("Shouldn't receive any value, status code should be unacceptable")
        } catch let error as ARError {
            switch error {
            case .unacceptableStatusCode(let statusCode, let response, _):
                try #require(error.errorCode == expectedError.errorCode)
                try #require(statusCode == 404)
                try #require(response != nil)
                try #require(error.localizedDescription == expectedError.localizedDescription)
            case .unexpectedMimeType, .missingData:
                Issue.record("This is not the error you are looking for")
            }
        } catch {
            Issue.record("Shouldn't receive any other error")
        }
    }

    @Test("Response has unexpected mime type")
    func testResponseHasUnexpectedMimeType() async throws {
        let expectedError = ARError.unexpectedMimeType(mimeType: "text/plain",
                                                       response: HTTPURLResponse(),
                                                       responseContent: .data(Data()))

        let provider = ArachneProvider<MyService>(urlSession: session)
        do {
            _ = try await provider.download(.unexpectedMimeType)
            Issue.record("Shouldn't receive any value, mime type should mismatch")
        } catch let error as ARError {
            switch error {
            case .unexpectedMimeType(let mimeType, _, _):
                try #require(error.errorCode == expectedError.errorCode)
                try #require(mimeType == "text/plain")
                try #require(error.localizedDescription == expectedError.localizedDescription)
            case .unacceptableStatusCode, .missingData:
                Issue.record("This is not the error you are looking for")
            }
        } catch {
            Issue.record("Shouldn't receive any other error")
        }
    }

    @Test("Plugin handles error response correctly")
    func testPluginHasErrorResponse() async throws {
        final class TestPlugin: ArachnePlugin {
            let confirmation: Confirmation

            init(confirmation: Confirmation) {
                self.confirmation = confirmation
            }

            func handle(error: any Error, request: URLRequest, output: AROutput?) {
                let urlString = try? MyServiceWithDefaults.notFound.url().absoluteString
                #expect(request.url?.absoluteString == urlString,
                         "Request URL in error is not equal to expected URL")
                #expect(output != nil)
                confirmation.confirm()
            }

            func handle(request: URLRequest) {
                let urlString = try? MyServiceWithDefaults.notFound.url().absoluteString
                #expect(request.url?.absoluteString == urlString)
                confirmation.confirm()
            }

            func handle(response: URLResponse, output: AROutput) {
                Issue.record("Should not have been called")
            }
        }

        await confirmation(expectedCount: 2) { confirmation in
            let plugin = TestPlugin(confirmation: confirmation)
            let provider = ArachneProvider<MyServiceWithDefaults>(urlSession: session).with(plugins: [plugin])

            do {
                _ = try await provider.data(.notFound)
                Issue.record("Shouldn't receive any value, status code should be unacceptable")
            } catch {
                // Nothing to do
            }
        }
    }

    @Test("Request modifier modifies the request correctly")
    func testRequestModifier() async throws {
        let requestModifier: @Sendable (MyService, inout URLRequest) async throws -> Void = { _, request in
            let url = request.url?.absoluteString ?? ""
            request.url = URL(string: "\(url)modified")
        }

        let provider = ArachneProvider<MyService>(urlSession: session).with(requestModifier: requestModifier)
        let modifiedRequest = try await provider.urlRequest(for: .jsonResponse)
        try #require(modifiedRequest.url == URL(string: "\(try MyService.jsonResponse.url())modified"),
                     "URL was not modified")
    }

    @Test("Provider initializes with custom URLSession")
    func testInit() async throws {
        final class TestURLSessionDelegate: NSObject, URLSessionDataDelegate {
            let confirmation: Confirmation

            init(confirmation: Confirmation) {
                self.confirmation = confirmation
            }

            func urlSession(_ session: URLSession,
                            task: URLSessionTask,
                            didFinishCollecting metrics: URLSessionTaskMetrics) {
                confirmation.confirm()
            }
        }

        try await confirmation(expectedCount: 3) { confirmation in
            let delegate = TestURLSessionDelegate(confirmation: confirmation)
            let customUrlSession = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
            var provider = ArachneProvider<MyService>(urlSession: customUrlSession)
            _ = try await provider.data(.plainText)

            provider = provider.with(plugins: [])
            _ = try await provider.data(.plainText)

            provider = provider.with(requestModifier: { _, _ in })
            _ = try await provider.data(.plainText)
        }

    }
}
