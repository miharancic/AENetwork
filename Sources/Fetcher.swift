/**
 *  https://github.com/tadija/AENetwork
 *  Copyright (c) Marko Tadić 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

open class Fetcher {

    // MARK: Types

    public struct Completion {
        public typealias ThrowableResult = (() throws -> Result) -> Void
    }

    public struct Result {
        public let response: HTTPURLResponse
        public let data: Data

        public func dictionary() throws -> [String : Any] {
            return try data.toDictionary()
        }

        public func array() throws -> [Any] {
            return try data.toArray()
        }
    }

    public enum Error: Swift.Error {
        case badResponse(HTTPURLResponse?)
    }

    // MARK: Singleton

    public static let shared = Fetcher()

    // MARK: Properties

    public let session: URLSession

    // MARK: Init

    public init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: API

    public func sendRequest(_ request: URLRequest, completion: @escaping Completion.ThrowableResult) {
        session.dataTask(with: request) { [weak self] data, response, error in
            if let response = response as? HTTPURLResponse, let data = data, error == nil {
                self?.handleValidResponse(response, with: data, from: request, completion: completion)
            } else {
                self?.handleResponseError(error, from: request, completion: completion)
            }
        }.resume()
    }

    // MARK: Helpers

    private func handleValidResponse(_ response: HTTPURLResponse,
                                with data: Data,
                                from request: URLRequest,
                                completion: Completion.ThrowableResult) {
        switch response.statusCode {
        case 200 ..< 300:
            completion {
                return Result(response: response, data: data)
            }
        default:
            completion {
                throw Error.badResponse(response)
            }
        }
    }

    private func handleResponseError(_ error: Swift.Error?,
                                     from request: URLRequest,
                                     completion: @escaping Completion.ThrowableResult) {
        if let error = error as NSError? {
            if error.domain == NSURLErrorDomain && error.code == NSURLErrorNetworkConnectionLost {
                // Retry request because of the iOS bug - SEE: https://github.com/AFNetworking/AFNetworking/issues/2314
                sendRequest(request, completion: completion)
            } else {
                completion {
                    throw error
                }
            }
        } else {
            completion {
                throw Error.badResponse(nil)
            }
        }
    }

}
