# Arachne

Arachne is a lightweight, minimalistic, zero dependencies networking layer for apps using [Combine](https://developer.apple.com/documentation/combine) developed in Swift, that provides an opinionated abstraction layer to remove boilerplate code.

Arachne aims to expose a Combine [Publisher](https://developer.apple.com/documentation/combine/publisher) even for `URLSession` tasks that don't have one yet.

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

    var headers: [String : String]? {
        switch self {
        case .postEndpoint:
            return nil
        default:
            return ["Accept" : "application/json"]
        }
    }

}
```

Then you can use them like this

```swift
import Combine
import SwiftUI

struct Info: Codable {
    let name: String
}

class MyApiClient {
    private let provider = ArachneProvider<MyAPIService>()

    func loadInfo() -> AnyPublisher<Info, Error> {
        return provider.request(.info)
            .decode(type: Info.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}

class MyInteractor: ObservableObject {
    private let apiClient = MyApiClient()
    private var cancellables = Set<AnyCancellable>()

    @Published var info: Info?

    func getInfo() {
        apiClient.loadInfo()
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    NSLog("Error: \(error.localizedDescription)")
                }
            } receiveValue: { info in
                self.info = info
            }
            .store(in: &cancellables)
    }
}

struct MyView: View {
    @ObservedObject var interactor: MyInteractor

    var body: some View {
        Text(interactor.info?.name ?? "")
            .onAppear {
                interactor.getInfo()
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
* `dataTask`
* `downloadTask`

Next step will be to add the remaining tasks 🚧

## Contributing

Contributions are welcome!
No special steps are required to get up and running developing this project, just clone and open in Xcode, the only requirement is for each PR to have proper unit tests and that all tests pass.

## License

This project is released under the [MIT License](https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE).

## Project status

This project is currently under active development.

## Why Arachne?

Thinking about networking my mind immediately went to the best "networkers" in nature: spiders.

Since I come from classical studies background I liked to use the Greek word for spider: Arachne (ᾰ̓ρᾰ́χνη). Arachne is also the name of the protagonist, a very talented weaver, of [a tale in Greek mythology](https://en.wikipedia.org/wiki/Arachne) and I felt it was really appropriate.
