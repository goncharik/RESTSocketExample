import Foundation

class WebSocketStream: AsyncSequence {
    typealias Element = URLSessionWebSocketTask.Message
    typealias AsyncIterator = AsyncThrowingStream<URLSessionWebSocketTask.Message, Error>.Iterator

    private var stream: AsyncThrowingStream<Element, Error>?
    private var continuation: AsyncThrowingStream<Element, Error>.Continuation?
    private let socket: URLSessionWebSocketTask
    private var isCanceled = false

    init(url: String, session: URLSession = URLSession.shared) {
        socket = session.webSocketTask(with: URL(string: url)!)
        stream = AsyncThrowingStream { continuation in
            self.continuation = continuation
            self.continuation?.onTermination = { @Sendable [socket, weak self] _ in
                self?.isCanceled = true
                socket.cancel()
            }
        }
        socket.resume()
    }

    func send(_ message: String) async throws {
        try await socket.send(.string(message))
    }

    func makeAsyncIterator() -> AsyncIterator {
        guard let stream = stream else {
            fatalError("stream was not initialized")
        }
        listenForMessages()
        return stream.makeAsyncIterator()
    }

    private func listenForMessages() {
        guard !isCanceled else { return }
        socket.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.continuation?.yield(message)
                self?.listenForMessages()
            case .failure(let error):
                self?.continuation?.finish(throwing: error)
            }
        }
    }

}

enum WebSocketError: Error {
    case invalidFormat
}

extension URLSessionWebSocketTask.Message {
    func transactionDetails() throws -> BitcoinTransactionDetails {
        switch self {
        case .string(let json):
            guard let data = json.data(using: .utf8) else {
                throw WebSocketError.invalidFormat
            }
            let message = try JSONDecoder.default.decode(BitcoinTransactionResponse.self, from: data)
            return message.x
        case .data:
            throw WebSocketError.invalidFormat
        @unknown default:
            throw WebSocketError.invalidFormat
        }
    }
}
