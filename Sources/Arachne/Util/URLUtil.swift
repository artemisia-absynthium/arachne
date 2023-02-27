//
// URLUtil.swift - URL and URLRequest building utils
// This source file is part of the Arachne open source project
//
// Copyright (c) 2021 - 2023 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation

enum URLUtil {
    static func composedUrl<T: ArachneService>(for target: T) throws -> URL {
        guard var urlComponents = URLComponents(string: target.baseUrl) else {
            throw URLError(.unsupportedURL, userInfo: [
                NSLocalizedDescriptionKey : "Unsupported URL",
                NSURLErrorFailingURLStringErrorKey : target.baseUrl
            ])
        }
        urlComponents.path.append(target.path)
        urlComponents.queryItems = target.queryStringItems?.map { queryItem in
            URLQueryItem(name: queryItem.name,
                         value: queryItem.value?.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed))
        }
        guard let url = urlComponents.url else {
            throw URLError(.unsupportedURL, userInfo: [
                NSLocalizedDescriptionKey : "Unsupported URL",
                NSURLErrorFailingURLStringErrorKey : urlComponents.description
            ])
        }
        return url
    }

    static func composedRequest<T: ArachneService>(for target: T,
                                                   url: URL,
                                                   timeoutInterval: Double? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = target.method.rawValue
        target.headers?.forEach { header in
            guard !URLRequest.reservedHeaders.contains(header.key) else {
                return
            }
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
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
