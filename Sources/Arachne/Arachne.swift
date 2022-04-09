import Foundation

/// Build an `enum` that extends this `Protocol` to represent your API service.
public protocol ArachneService {
    /// The complete base URL, example: `"https://www.myserver.io/v1"`
    var baseUrl: String { get }

    /// The path of the endpoint
    var path: String { get }

    /// Optional query string items
    var queryStringItems: [URLQueryItem]? { get }

    /// The HTTP method of the endpoint
    var method: HttpMethod { get }

    /// Optional request body encoded data
    var body: Data? { get }

    /// Optional request headers
    var headers: [String: String]? { get }

    /// HTTP response status codes that you consider valid, default value is [200...299].
    var validCodes: [Int] { get }
}

/// HTTP methods enumeration
public enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case head = "HEAD"
}

public extension ArachneService {
    var validCodes: [Int] {
        return Array(200...299)
    }
}
