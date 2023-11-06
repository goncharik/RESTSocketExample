import Dependencies
import Foundation

protocol AuthClient {
    func isAuthorized() -> Bool
    func signIn(_ email: String, _ password: String) async throws -> AuthToken
    func logout(_ sessionId: String?) async
    func currentSession() async throws -> SessionInfo
    func transactionsSocketStream() -> WebSocketStream
}

final class AuthClientImpl: AuthClient {
    private let appEnv: AppEnv
    private let apiClient: ApiClient

    init(
        appEnv: AppEnv,
        apiClient: ApiClient
    ) {
        self.appEnv = appEnv
        self.apiClient = apiClient
    }

    func isAuthorized() -> Bool {
        apiClient.isAuthorized()
    }

    func signIn(_ email: String, _ password: String) async throws -> AuthToken {
        try await apiClient.signIn(with: email, password: password)
    }

    func currentSession() async throws -> SessionInfo {
        struct CurrentSessionResponse: Codable {
            let info: SessionInfo
        }

        let response: CurrentSessionResponse = try await apiClient.get(path: "accounts/current", params: [:])
        return response.info
    }

    func transactionsSocketStream() -> WebSocketStream {
        WebSocketStream(url: appEnv.socketUrl)
    }

    func logout(_ sessionId: String?) async {
        struct Body: Codable {
            var sessionId: String
        }
        if let sessionId {
            let _: EmptyModel? = try? await apiClient.post(path: "accounts/sessions/end", body: Body(sessionId: sessionId))
        }
        await apiClient.logout()
    }
}

// MARK: - DI

extension DependencyValues {
    var authClient: any AuthClient {
        get { self[AuthClientKey.self] }
        set { self[AuthClientKey.self] = newValue }
    }
}

enum AuthClientKey: DependencyKey {
    static var liveValue: any AuthClient {
        @Dependency(\.apiClient) var apiClient

        return AuthClientImpl(
            appEnv: AppEnv.live,
            apiClient: apiClient
        )
    }
}
