import Foundation

/// You typically implement this protocol in an `enum` to define an API having a specific `baseURL` and define endpoints as `case`s of this `enum`.
///
/// For example:
/// ```
/// enum PetStore {
///     case pets(limit: Int)
///     case pet(id: String)
/// }
///
/// extension PetStore: ArachneService {
///     var baseUrl: String {
///         return "https://www.myserver.io/v1"
///     }
///
///     var path: String {
///         switch self {
///         case .pets:
///             return "/pets"
///         case .pet(let id):
///             return "/pets/\(id)"
///         }
///     }
///
///     var queryStringItems: [URLQueryItem]? {
///         switch self {
///         case .pets(let limit):
///             return [
///                 URLQueryItem(name: "limit", value: "\(limit)")
///             ]
///         default:
///             return nil
///         }
///     }
///
///     var method: HttpMethod {
///         return .get
///     }
///
///     var body: Data? {
///         return nil
///     }
///
///     var headers: [String : String]? {
///         return ["Accept" : "application/json"]
///     }
///
///     var validCodes: [Int] {
///         return [200]
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
    var headers: [String : String]? { get }

    /// HTTP response status codes that you consider valid, default value is [200...299].
    var validCodes: [Int] { get }

}

public extension ArachneService {
    var validCodes: [Int] {
        return Array(200...299)
    }
}

/// HTTP methods enumeration
public enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case head = "HEAD"
}
