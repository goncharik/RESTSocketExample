import XCTest

@testable import RESTSocketExample

final class AuthClientTests: XCTestCase {

    var sut: AuthClientImpl!
    var appEnvMock: AppEnv!
    var apiClientMock: ApiClientMock!

    override func setUpWithError() throws {
        try super.setUpWithError()
        appEnvMock = .mock
        apiClientMock = ApiClientMock()
        sut = AuthClientImpl(appEnv: appEnvMock, apiClient: apiClientMock)
    }

    override func tearDownWithError() throws {
        sut = nil
        appEnvMock = nil
        apiClientMock = nil
        try super.tearDownWithError()
    }

    func testCheckAppConfigurationSuccess() throws {
        // Given
        appEnvMock.appAuthType = .oauth(clientId: "valid-client-id", clientSecret: "valid-client-secret")
        sut = AuthClientImpl(appEnv: appEnvMock, apiClient: apiClientMock)

        // Then
        XCTAssertNoThrow(try sut.checkAppConfiguration())
    }

    func testCheckAppConfigurationFailure() throws {
        // Given
        appEnvMock.appAuthType = .oauth(clientId: "empty-client-id", clientSecret: "empty-client-secret")
        sut = AuthClientImpl(appEnv: appEnvMock, apiClient: apiClientMock)

        // When
        XCTAssertThrowsError(try sut.checkAppConfiguration()) { error in
            // Then
            XCTAssertEqual(error as? ApiError, ApiError.invalidAppConfig)
        }
    }

    func testOAuthURL() {
        // Given
        appEnvMock.oauthUrl = "https://example.com/oauth"
        appEnvMock.appAuthType = .oauth(clientId: "valid-client-id", clientSecret: "valid-client-secret")
        appEnvMock.defaultRedirectUri = "default-redirect-uri"
        sut = AuthClientImpl(appEnv: appEnvMock, apiClient: apiClientMock)
        
        let expectedURL = URL(string: "https://example.com/oauth?client_id=valid-client-id&response_type=code&redirect_uri=default-redirect-uri&token_access_type=offline&force_reapprove=true&disable_signup=true")!

        // When
        let generatedURL = sut.oauthURL()

        // Then
        XCTAssertEqual(generatedURL, expectedURL)
    }

    func testIsAuthorized() {
        apiClientMock.isAuthorizedReturnValue = true
        XCTAssertTrue(sut.isAuthorized())

        apiClientMock.isAuthorizedReturnValue = false
        XCTAssertFalse(sut.isAuthorized())
    }

    func testSignIn() async throws {
        // Given
        let authCode = "test-auth-code"

        // When
        try await sut.signIn(authCode)

        // Then
        XCTAssertEqual(apiClientMock.signInWithCallsCount, 1)
        XCTAssertEqual(apiClientMock.signInWithReceivedCode, authCode)
    }

    func testLogout() async {
        // When
        await sut.logout()

        // Then
        XCTAssertEqual(apiClientMock.logoutCallsCount, 1)
    }

}
