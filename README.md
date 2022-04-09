# Arachne

[![Swift](https://github.com/artemisia-absynthium/arachne/actions/workflows/swift.yml/badge.svg)](https://github.com/artemisia-absynthium/arachne/actions/workflows/swift.yml)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/d00911ec2c7048888abff2642b7ca6f5)](https://www.codacy.com/gh/artemisia-absynthium/arachne/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=artemisia-absynthium/arachne&amp;utm_campaign=Badge_Grade)
[![codecov](https://codecov.io/gh/artemisia-absynthium/arachne/branch/main/graph/badge.svg?token=SE49QJW0M3)](https://codecov.io/gh/artemisia-absynthium/arachne)

Arachne is a lightweight, minimalistic, zero dependencies networking layer for apps using [Swift Concurrency (async/await)](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html) or [Combine](https://developer.apple.com/documentation/combine) (support to Combine will be discontinued) developed in Swift, that provides an opinionated abstraction layer to remove boilerplate code.

Arachne aims to backport async/await `URLSession` tasks to macOS 10.15, iOS 13, iPadOS 13, tvOS 13 and watchOS 7, while the availability of their native counterpart in the Foundation framework is iOS 15.0+, iPadOS 15.0+, macOS 12.0+, Mac Catalyst 15.0+, tvOS 15.0+, watchOS 8.0+.

This library's design was inspired by [Moya](https://github.com/Moya/Moya), but differently from Moya, Arachne uses only the standard [Foundation framework](https://developer.apple.com/documentation/foundation/url_loading_system) (e.g. `URLSession`).

This makes Arachne suitable for recently created or migrated apps that make use of Apple's frameworks, instead of third party ones, like [Alamofire](https://github.com/Alamofire/Alamofire) or [RxSwift](https://github.com/ReactiveX/RxSwift).

## Usage

You start by defining your APIs like this

```swift
import Foundation
import Arachne

enum MyAPIService {
    case info
    case userProfile(username: String)
    case postEndpoint(body: MyCodableObject, limit: Int)
}

extension MyAPIService: ArachneService {
    var baseUrl: String {
        switch self {
        default:
            return "https://myapiservice.com"
        }
    }

    var path: String {
        switch self {
        case .info:
            return "/info"
        case .userProfile(let username):
            return "/users/\(username)"
        case .postEndpoint:
            return "/postendpoint"
        }
    }

    var queryStringItems: [URLQueryItem]? {
        switch self {
        case .postEndpoint(_, let limit):
            return [
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        default:
            return nil
        }
    }

    var method: HttpMethod {
        switch self {
        case .postEndpoint:
            return .post
        default:
            return .get
        }
    }

    var body: Data? {
        switch self{
        case .postEndpoint(let myCodableObject, _):
            return try? JSONEncoder().encode(myCodableObject)
        default:
            return nil
        }
    }

    var headers: [String: String]? {
        switch self {
        case .postEndpoint:
            return nil
        default:
            return ["Accept": "application/json"]
        }
    }
}
```

Then you can use them like this

Declare your provider

```swift
let provider = ArachneProvider<MyAPIService>()
```

Get data from your endpoint

```swift
let (data, _) = try await provider.data(.info)
```

Let's see it assembled in an extract of a SwiftUI app

```swift
import SwiftUI
import Arachne
import os

struct Info: Codable {
    let name: String
}

class MyApiClient {
    private let provider = ArachneProvider<MyAPIService>()

    func loadInfo() async throws -> Info {
        let (data, _) = try await provider.data(.info)
        return try JSONDecoder().decode(Info.self, from: data)
    }
}

class MyInteractor: ObservableObject {
    private let apiClient = MyApiClient()
    private let logger = Logger(subsystem: "Arachne", category: "MyInteractor")

    @Published var info: Info?

    func getInfo() async {
        do {
            self.info = try await apiClient.loadInfo()
        } catch {
            logger.error("Error: \(error.localizedDescription)")
        }
    }
}

struct MyView: View {
    @ObservedObject var interactor: MyInteractor

    var body: some View {
        Text(interactor.info?.name ?? "")
            .onAppear {
                Task {
                    await interactor.getInfo()
                }
            }
    }
}
```

## Migrate from 0.3.0 to 0.4.0

A function using a Combine publisher, for example:

```swift
func getInfo() {
    apiClient.loadInfo()
        .sink { completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                // Handle error
            }
        } receiveValue: { info in
            self.info = info
        }
        .store(in: &cancellables)
}
```

can be easily migrated like this

```swift
func getInfo() async {
    do {
        self.info = try await apiClient.loadInfo()
    } catch {
        // Handle error
    }
}
```

or if you cannot make your function async

```swift
func getInfo() {
    Task {
        do {
            self.info = try await apiClient.loadInfo()
        } catch {
            // Handle error
        }
    }
}
```

## Installation

### Swift Package Manager

#### Using Xcode UI

Go to your Project Settings -> Swift Packages and add Arachne from there.

#### Not using Xcode UI

Add the following as a dependency to your `Package.swift`:

```swift
.package(url: "https://github.com/artemisia-absynthium/arachne.git", .upToNextMajor(from: "0.2.0"))
```
and then specify "Arachne" as a dependency of the Target in which you wish to use it.

### Cocoapods

_Note: If you can choose, please use Swift Package Manager, support for Cocoapods may be discontinued in future versions of this library_

Add the following entry to your `Podfile`:

```ruby
pod 'Arachne'
```

## Roadmap

Currently supported tasks are
*   `dataTask`
*   `downloadTask`

Next step will be to add the remaining tasks 🚧

## Contributing

Contributions are welcome!
No special steps are required to get up and running developing this project, just clone and open in Xcode, the only requirement is for each PR to have proper unit tests and that all tests pass.

## License

This project is released under the [MIT License](https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE).

## Project status

This project recently experienced a shift of goal, while the initial goal of this library was to provide Combine publishers for tasks that didn't have one, the introduction of async/await in Swift suddenly made using Combine for network requests look cumbersome and this is why no new Combine tasks will be added.
Instead the new goal of this library is to backport async/await `URLSession` tasks to macOS 10.15, iOS 13, iPadOS 13, tvOS 13 and watchOS 7, while the availability of their native counterpart in the Foundation framework is iOS 15.0+, iPadOS 15.0+, macOS 12.0+, Mac Catalyst 15.0+, tvOS 15.0+, watchOS 8.0+.

## Why Arachne

Thinking about networking my mind immediately went to the best "networkers" in nature: spiders.

Since I come from classical studies background I liked to use the Greek word for spider: Arachne (ᾰ̓ρᾰ́χνη). Arachne is also the name of the protagonist, a very talented weaver, of [a tale in Greek mythology](https://en.wikipedia.org/wiki/Arachne) and I felt it was really appropriate.
