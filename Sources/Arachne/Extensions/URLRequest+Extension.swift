//
//  URLRequest+Extension.swift
//  
//
//  Created by Cristina De Rito on 01/10/21.
//

import Foundation

extension URLRequest {
    /// `URLRequest` reserved headers, as reported in the official documentation:
    /// https://developer.apple.com/documentation/foundation/nsurlrequest#1776617
    /// with the exception that `Authorization` is omitted to enable users to set it,
    /// according to Apple's official response in this topic: https://developer.apple.com/forums/thread/89811
    static let reservedHeaders = [
        "Content-Length",
        "Connection",
        "Host",
        "Proxy-Authenticate",
        "Proxy-Authorization",
        "WWW-Authenticate"
    ]
}
