import Dependencies
import Foundation

enum AuthError: Error {
    case missingToken
    case invalidToken
}

protocol AuthSessionProtocol {
    func isAuthorized() -> Bool
    func validToken() async throws -> String
    @discardableResult
    func refreshToken() async throws -> AuthToken
    @discardableResult
    func obtainToken(for email: String, password: String) async throws -> AuthToken
    func logout() async
}

actor AuthSession: AuthSessionProtocol {
    private nonisolated let currentToken: Isolated<AuthToken?>

    private var refreshTask: Task<AuthToken, Error>?

    private let appEnv: AppEnv
    private let tokenStorage: TokenStorage
    private let httpClient: HTTPClient

    init(appEnv: AppEnv, tokenStorage: TokenStorage, httpClient: HTTPClient) {
        self.appEnv = appEnv
        self.tokenStorage = tokenStorage
        self.httpClient = httpClient
        let token = tokenStorage.load()
        currentToken = Isolated(token, didSet: { _, newValue in
            tokenStorage.save(newValue)
        })
    }

    nonisolated func isAuthorized() -> Bool {
        currentToken.value != nil
    }

    func validToken() async throws -> String {
        if let handle = refreshTask {
            return try await handle.value.token
        }

        guard let token = currentToken.value else {
            throw AuthError.missingToken
        }

        if token.isValid {
            return token.token
        }

        return try await refreshToken().token
    }

    @discardableResult
    func refreshToken() async throws -> AuthToken {
        if let refreshTask {
            return try await refreshTask.value
        }

        guard let refreshToken = currentToken.value?.token else {
            throw AuthError.missingToken
        }

        let task = Task { () throws -> AuthToken in
            defer { refreshTask = nil }
            print("Refreshing token...")

            let tokenURL = URL(string: appEnv.baseUrl + "accounts/sessions/refresh")!
            var request = URLRequest(url: tokenURL)
            request.httpMethod = "POST"
            

            request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            do {
                var newToken: AuthToken = try await httpClient.model(for: request)
                newToken.createdAt = Date()                
                currentToken.value = newToken
                return newToken
            } catch {
                print("Failed to refresh token: \(error)")
                throw AuthError.invalidToken
            }
        }

        refreshTask = task

        return try await task.value
    }

    @discardableResult
    func obtainToken(for email: String, password: String) async throws -> AuthToken {
        let tokenURL = URL(string: appEnv.baseUrl + "accounts/auth")!

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"

        let bodyParameters: [String: String] = [
            "email": email,
            "password": password,
        ]

        let bodyData = try JSONEncoder.default.encode(bodyParameters)

        request.httpBody = bodyData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            var accessToken: AuthToken = try await httpClient.model(for: request)
            accessToken.createdAt = Date()
            currentToken.value = accessToken

            return accessToken
        } catch {
            print(error)
            fatalError()
        }
    }

    func logout() {
        currentToken.value = nil
    }
}

// MARK: - DI

extension DependencyValues {
    var authSession: AuthSession {
        get { self[AuthSession.self] }
        set { self[AuthSession.self] = newValue }
    }
}

extension AuthSession: DependencyKey {
    static var liveValue: AuthSession {
        @Dependency(\.httpClient) var httpClient
        @Dependency(\.tokenStorage) var tokenStorage

        return AuthSession(
            appEnv: .live,
            tokenStorage: tokenStorage,
            httpClient: httpClient
        )
    }
}
