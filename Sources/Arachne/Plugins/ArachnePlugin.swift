//
//  ArachnePlugin.swift
//  
//
//  Created by Cristina De Rito on 01/10/21.
//

import Foundation

public protocol ArachnePlugin {
    func handle(error: Error, output: Any?)
    func handle(request: URLRequest)
    func handle(response: URLResponse, data: Any)
}
