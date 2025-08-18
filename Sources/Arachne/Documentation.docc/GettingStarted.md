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
        "https://myapiservice.com"
    }

    var path: String {
        switch self {
        case .info:
            "/info"
        case .userProfile(let username):
            "/users/\(username)"
        case .postEndpoint:
            "/postendpoint"
        }
    }

    var queryStringItems: [URLQueryItem]? {
        switch self {
        case .postEndpoint(_, let limit):
            [URLQueryItem(name: "limit", value: "\(limit)")]
        default:
            nil
        }
    }

    var method: HttpMethod {
        switch self {
        case .postEndpoint:
            .post
        default:
            .get
        }
    }

    var body: Data? {
        switch self {
        case .postEndpoint(let myCodableObject, _):
            try? JSONEncoder().encode(myCodableObject)
        default:
            nil
        }
    }

    var headers: [String : String]? {
        switch self {
        case .postEndpoint:
            nil
        default:
            ["Accept": "application/json"]
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

@Observable
class MyState {
    private let apiClient = MyApiClient()
    private let logger = Logger(subsystem: "Arachne", category: "MyInteractor")

    var info: Info?

    func getInfo() async {
        do {
            self.info = try await apiClient.loadInfo()
        } catch {
            logger.error("Error: \(error.localizedDescription)")
        }
    }
}

struct MyView: View {
    @State var state = MyState()

    var body: some View {
        Text(state.info?.name ?? "No name")
            .task {
                await viewModel.getInfo()
            }
    }
}
```

## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
