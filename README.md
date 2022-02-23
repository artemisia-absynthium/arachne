# Arachne

Arachne is a networking layer for Swift+[Combine](https://developer.apple.com/documentation/combine) apps that provides an opinionated abstraction to hide some common boilerplate code.

Arachne aims to expose a Combine [Publisher](https://developer.apple.com/documentation/combine/publisher) even for `URLSession` tasks that don't have one yet.

Currently supported tasks are
* `dataTask`
* `downloadTask`

Other tasks are still WIP 🚧

This library's design was inspired by [Moya](https://github.com/Moya/Moya), it differs from Moya in the fact that Arachne uses directly [Foundation's URLSession](https://developer.apple.com/documentation/foundation/url_loading_system) APIs.

This makes Arachne really lightweight and minimalist and suitable for newer apps that make use of Apple's newest frameworks.

## Installation

### Swift Package Manager

_Note: Instructions below are for using SwiftPM without the Xcode UI. It's the easiest to go to your Project Settings -> Swift Packages and add Arachne from there._

To integrate using Apple's Swift package manager, without using Xcode UI, add the following as a dependency to your Package.swift:

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

## Usage

You start by defining your APIs like this

```swift
import Foundation
import Arachne

enum MyAPIService {
    case info
    case userProfile(String)
    case postEndpoint(MyCodableObject)
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
        case .postEndpoint:
            return [
                URLQueryItem(name: "v", value: "1")
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
        case .postEndpoint(let myCodableObject):
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

Then you could use them for example like this (the `ArachneProvider` is in the `WebRepository` for simplicity, you are encouraged to use an `ArachneProvider` for each service and abstract your providers into a separate class).

```swift
import Combine
import SwiftUI

struct Info: Codable {
    let name: String
}

class MyWebRepository {
    private let provider = ArachneProvider<MyAPIService>()

    func loadInfo() -> AnyPublisher<Info, Error> {
        return provider.request(.info)
            .decode(type: Info.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}

class MyInteractor: ObservableObject {
    private let webRepository = MyWebRepository()
    private var cancellables = Set<AnyCancellable>()

    @Published var info: Info?

    func getInfo() {
        webRepository.loadInfo()
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

## Roadmap

Next steps will be to add

## Contributing

State if you are open to contributions and what your requirements are for accepting them.
For people who want to make changes to your project, it's helpful to have some documentation on how to get started. Perhaps there is a script that they should run or some environment variables that they need to set. Make these steps explicit. These instructions could also be useful to your future self.
You can also document commands to lint the code or run tests. These steps help to ensure high code quality and reduce the likelihood that the changes inadvertently break something. Having instructions for running tests is especially helpful if it requires external setup, such as starting a Selenium server for testing in a browser.

## License

This project is released under the [MIT License](https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE).

## Project status

This project is currently under active development.
