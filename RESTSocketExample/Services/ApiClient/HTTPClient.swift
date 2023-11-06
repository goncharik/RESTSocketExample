import Dependencies
import Foundation

protocol HTTPClient {
    func data(for: URLRequest) async throws -> (Data, URLResponse)
    func downloadTask(with request: URLRequest, completionHandler: @escaping @Sendable (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask
}

extension URLSession: HTTPClient {}

// MARK: - DI

extension DependencyValues {
    var httpClient: any HTTPClient {
        get { self[HTTPClientKey.self] }
        set { self[HTTPClientKey.self] = newValue }
    }
}

enum HTTPClientKey: DependencyKey {
    static var liveValue: any HTTPClient {
        URLSession.shared
    }
}

// MARK: - HTTPClientMock

final class HTTPClientMock: HTTPClient {
    
   // MARK: - data

    var dataForThrowableError: Error?
    var dataForCallsCount = 0
    var dataForCalled: Bool {
        dataForCallsCount > 0
    }
    var dataForReceivedFor: URLRequest?
    var dataForReceivedInvocations: [URLRequest] = []
    var dataForReturnValue: (Data, URLResponse)!
    var dataForClosure: ((URLRequest) throws -> (Data, URLResponse))?

    func data(for req: URLRequest) throws -> (Data, URLResponse) {
        if let error = dataForThrowableError {
            throw error
        }
        dataForCallsCount += 1
        dataForReceivedFor = req
        dataForReceivedInvocations.append(req)
        return try dataForClosure.map({ try $0(req) }) ?? dataForReturnValue
    }
    
   // MARK: - downloadTask

    var downloadTaskWithCompletionHandlerCallsCount = 0
    var downloadTaskWithCompletionHandlerCalled: Bool {
        downloadTaskWithCompletionHandlerCallsCount > 0
    }
    var downloadTaskWithCompletionHandlerReceivedArguments: (request: URLRequest, completionHandler: (URL?, URLResponse?, Error?) -> Void)?
    var downloadTaskWithCompletionHandlerReceivedInvocations: [(request: URLRequest, completionHandler: (URL?, URLResponse?, Error?) -> Void)] = []
    var downloadTaskWithCompletionHandlerReturnValue: URLSessionDownloadTask!
    var downloadTaskWithCompletionHandlerClosure: ((URLRequest, @Sendable @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask)?

    func downloadTask(with request: URLRequest, completionHandler: @Sendable @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        downloadTaskWithCompletionHandlerCallsCount += 1
        downloadTaskWithCompletionHandlerReceivedArguments = (request: request, completionHandler: completionHandler)
        downloadTaskWithCompletionHandlerReceivedInvocations.append((request: request, completionHandler: completionHandler))
        return downloadTaskWithCompletionHandlerClosure.map({ $0(request, completionHandler) }) ?? downloadTaskWithCompletionHandlerReturnValue
    }
}
