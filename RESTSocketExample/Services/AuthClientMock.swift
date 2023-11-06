import Foundation

// MARK: - AuthClientMock

final class AuthClientMock: AuthClient {
    
   // MARK: - isAuthorized

    var isAuthorizedCallsCount = 0
    var isAuthorizedCalled: Bool {
        isAuthorizedCallsCount > 0
    }
    var isAuthorizedReturnValue: Bool!
    var isAuthorizedClosure: (() -> Bool)?

    func isAuthorized() -> Bool {
        isAuthorizedCallsCount += 1
        return isAuthorizedClosure.map({ $0() }) ?? isAuthorizedReturnValue
    }
    
   // MARK: - signIn

    var signInThrowableError: Error?
    var signInCallsCount = 0
    var signInCalled: Bool {
        signInCallsCount > 0
    }
    var signInReceivedArguments: (email: String, password: String)?
    var signInReceivedInvocations: [(email: String, password: String)] = []
    var signInReturnValue: AuthToken!
    var signInClosure: ((String, String) throws -> AuthToken)?

    func signIn(_ email: String, _ password: String) throws -> AuthToken {
        if let error = signInThrowableError {
            throw error
        }
        signInCallsCount += 1
        signInReceivedArguments = (email: email, password: password)
        signInReceivedInvocations.append((email: email, password: password))
        return try signInClosure.map({ try $0(email, password) }) ?? signInReturnValue
    }
    
   // MARK: - logout

    var logoutCallsCount = 0
    var logoutCalled: Bool {
        logoutCallsCount > 0
    }
    var logoutClosure: (() -> Void)?

    func logout(_ sessionId: String?) {
        logoutCallsCount += 1
        logoutClosure?()
    }
    
   // MARK: - currentSession

    var currentSessionThrowableError: Error?
    var currentSessionCallsCount = 0
    var currentSessionCalled: Bool {
        currentSessionCallsCount > 0
    }
    var currentSessionReturnValue: SessionInfo = .mock
    var currentSessionClosure: (() throws -> SessionInfo)?

    func currentSession() throws -> SessionInfo {
        if let error = currentSessionThrowableError {
            throw error
        }
        currentSessionCallsCount += 1
        return try currentSessionClosure.map({ try $0() }) ?? currentSessionReturnValue
    }

    // MARK: - transactionsSocketStream

    var transactionsSocketStreamCallsCount = 0
    var transactionsSocketStreamCalled: Bool {
        transactionsSocketStreamCallsCount > 0
    }
    var transactionsSocketStreamReturnValue: WebSocketStream = WebSocketStream(url: "wss://ws.blockchain.info/inv")
    var transactionsSocketStreamClosure: (() -> WebSocketStream)?

    func transactionsSocketStream() -> WebSocketStream {
        transactionsSocketStreamCallsCount += 1
        return transactionsSocketStreamClosure.map({ $0() }) ?? transactionsSocketStreamReturnValue
    }
}
