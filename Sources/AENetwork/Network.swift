/**
 *  https://github.com/tadija/AENetwork
 *  Copyright (c) Marko Tadić 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

open class Network {
    
    // MARK: Types
    
    public struct Completion {
        public typealias ThrowData = (() throws -> Data) -> Void
        public typealias ThrowDictionary = (() throws -> [String : Any]) -> Void
        public typealias ThrowArray = (() throws -> [Any]) -> Void
    }
    
    public enum Error: Swift.Error {
        case badRequest
        case badResponse
    }
    
    // MARK: Singleton
    
    public static let shared = Network(session: .shared, parser: .shared, cache: .shared, downloader: .shared)

    // MARK: Properties

    public let session: URLSession

    public let parser: Parser
    public let cache: Cache
    
    public let downloader: Downloader

    // MARK: Init
    
    public init(session: URLSession = .shared,
                parser: Parser = .init(),
                cache: Cache = .init(),
                downloader: Downloader = .init()) {
        self.session = session
        self.parser = parser
        self.cache = cache
        self.downloader = downloader
    }

}

// MARK: - Fetch

public extension Network {
    
    // MARK: API
    
    public func fetchData(with request: URLRequest, completion: @escaping Completion.ThrowData) {
        if let cachedResponse = cache.loadResponse(for: request) {
            completion {
                return cachedResponse.data
            }
        } else {
            sendRequest(request, completion: completion)
        }
    }
    
    public func fetchDictionary(with request: URLRequest, completion: @escaping Completion.ThrowDictionary) {
        fetchData(with: request) { [weak self] (closure) -> Void in
            do {
                let data = try closure()
                let dictionary = try self?.parser.jsonDictionary(from: data) ?? [String : Any]()
                completion {
                    return dictionary
                }
            } catch {
                completion {
                    throw error
                }
            }
        }
    }
    
    public func fetchArray(with request: URLRequest, completion: @escaping Completion.ThrowArray) {
        fetchData(with: request) { [weak self] (closure) -> Void in
            do {
                let data = try closure()
                let array = try self?.parser.jsonArray(from: data) ?? [Any]()
                completion {
                    return array
                }
            } catch {
                completion {
                    throw error
                }
            }
        }
    }
    
}

// MARK: - Request / Response

extension Network {
    
    fileprivate func sendRequest(_ request: URLRequest, completion: @escaping Completion.ThrowData) {
        session.dataTask(with: request) { [weak self] data, response, error in
            if let response = response as? HTTPURLResponse, let data = data, error == nil {
                self?.handleResponse(response, with: data, from: request, completion: completion)
            } else {
                self?.handleResponseError(error as? Network.Error, from: request, completion: completion)
            }
        }.resume()
    }
    
    private func handleResponse(_ response: HTTPURLResponse,
                                with data: Data,
                                from request: URLRequest,
                                completion: Completion.ThrowData) {
        switch response.statusCode {
        case 200 ..< 300:
            if let delegate = cache.delegate, delegate.shouldCacheResponse(from: request) {
                cache.saveResponse(response, with: data, from: request)
            }
            completion {
                return data
            }
        default:
            completion {
                throw Error.badResponse
            }
        }
    }
    
    private func handleResponseError(_ error: Error?,
                                     from request: URLRequest,
                                     completion: @escaping Completion.ThrowData) {
        if let error = error as NSError? {
            if error.domain == NSURLErrorDomain && error.code == NSURLErrorNetworkConnectionLost {
                // Retry request because of the iOS bug - SEE: https://github.com/AFNetworking/AFNetworking/issues/2314
                fetchData(with: request, completion: completion)
            } else {
                completion {
                    throw error
                }
            }
        } else {
            completion {
                throw Error.badResponse
            }
        }
    }
    
}
