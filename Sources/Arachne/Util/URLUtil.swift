//
//  URLUtil.swift
//  
//
//  Created by Cristina De Rito on 07/10/21.
//

import Foundation

class URLUtil {

    class func composedUrl<T: ArachneService>(for target: T) throws -> URL {
        guard var urlComponents = URLComponents(string: target.baseUrl) else {
            throw ARError.malformedUrl(target.baseUrl)
        }
        urlComponents.path.append(target.path)
        urlComponents.queryItems = target.queryStringItems?.map({ queryItem in
            URLQueryItem(name: queryItem.name, value: queryItem.value?.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed))
        })
        guard let url = urlComponents.url else {
            throw ARError.malformedUrl(urlComponents.description)
        }
        return url
    }

    class func composedRequest<T: ArachneService>(for target: T, url: URL, timeoutInterval: Double? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = target.method.rawValue
        target.headers?.forEach({ header in
            guard !URLRequest.reservedHeaders.contains(header.key) else {
                return
            }
            request.addValue(header.value, forHTTPHeaderField: header.key)
        })
        if let body = target.body {
            if (request.value(forHTTPHeaderField: "Content-Type") ?? "").isEmpty {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            request.httpBody = body
        }
        if let timeoutInterval = timeoutInterval {
            request.timeoutInterval = timeoutInterval
        }
        return request
    }

}
