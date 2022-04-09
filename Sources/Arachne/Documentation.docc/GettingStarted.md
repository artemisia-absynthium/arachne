# Getting Started with Arachne

Create an API service definition and make calls to its endpoints.

## Create your service definition

You start by defining your APIs

For example:
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

## Call endpoints

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

class MyViewModel: ObservableObject {
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
    @ObservedObject var viewModel: MyViewModel

    var body: some View {
        Text(viewModel.info?.name ?? "")
            .onAppear {
                Task {
                    await viewModel.getInfo()
                }
            }
    }
}
```

## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
