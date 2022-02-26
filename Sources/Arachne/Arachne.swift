import Foundation

/// You typically implement this protocol in an `enum` to define an API
/// having a specific `baseURL` and define endpoints as `case`s of this `enum`.
///
/// For example:
/// ```swift
/// import Foundation
///
/// enum MyAPIService {
///     case info
///     case userProfile(username: String)
///     case postEndpoint(body: MyCodableObject, limit: Int)
/// }
///
/// extension MyAPIService: ArachneService {
///     var baseUrl: String {
///         switch self {
///         default:
///             return "https://myapiservice.com"
///         }
///     }
///
///     var path: String {
///         switch self {
///         case .info:
///             return "/info"
///         case .userProfile(let username):
///             return "/users/\(username)"
///         case .postEndpoint:
///             return "/postendpoint"
///         }
///     }
///
///     var queryStringItems: [URLQueryItem]? {
///         switch self {
///         case .postEndpoint(_, let limit):
///             return [
///                 URLQueryItem(name: "limit", value: "\(limit)")
///             ]
///         default:
///             return nil
///         }
///     }
///
///     var method: HttpMethod {
///         switch self {
///         case .postEndpoint:
///             return .post
///         default:
///             return .get
///         }
///     }
///
///     var body: Data? {
///         switch self{
///         case .postEndpoint(let myCodableObject, _):
///             return try? JSONEncoder().encode(myCodableObject)
///         default:
///             return nil
///         }
///     }
///
///     var headers: [String: String]? {
///         switch self {
///         case .postEndpoint:
///             return nil
///         default:
///             return ["Accept": "application/json"]
///         }
///     }
/// }
/// ```
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
