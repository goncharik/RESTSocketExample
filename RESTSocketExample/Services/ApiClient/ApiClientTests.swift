import XCTest

@testable import RESTSocketExample

final class ApiClientTests: XCTestCase {
    struct MockCodableModel: Codable, Equatable {
        var mock: String = "mock"
    }

    var apiClient: ApiClientImpl!
    var appEnvMock: AppEnv!
    var httpClientMock: HTTPClientMock!
    var authSessionMock: AuthSessionProtocolMock!

    override func setUpWithError() throws {
        appEnvMock = .mock
        httpClientMock = HTTPClientMock()
        authSessionMock = AuthSessionProtocolMock()
        apiClient = ApiClientImpl(appEnv: appEnvMock, httpClient: httpClientMock, authSession: authSessionMock)
    }

    override func tearDownWithError() throws {
        apiClient = nil
        appEnvMock = nil
        httpClientMock = nil
        authSessionMock = nil
    }

    func testIsAuthorized() {
        authSessionMock.isAuthorizedReturnValue = true
        XCTAssertTrue(apiClient.isAuthorized())

        authSessionMock.isAuthorizedReturnValue = false
        XCTAssertFalse(apiClient.isAuthorized())
    }

    func testSignIn() async throws {
        // Given
        let authCode = "test-auth-code"
        authSessionMock.obtainTokenForReturnValue = AuthToken(
            accessToken: "accessToken", tokenType: "tokenType", expiresIn: 100, createdAt: Date()
        )

        // When
        try await apiClient.signIn(with: authCode)

        // Then
        XCTAssertEqual(authSessionMock.obtainTokenForCallsCount, 1)
        XCTAssertEqual(authSessionMock.obtainTokenForReceivedAuthorizationCode, authCode)
    }

    func testLogout() async {
        // When
        await apiClient.logout()

        // Then
        XCTAssertTrue(authSessionMock.logoutCalled)
    }

    func testGetRequest() async throws {
        // Given
        let expectedResult = MockCodableModel()
        let mockParams = ["key": "value"]
        httpClientMock.dataForReturnValue = try (JSONEncoder.default.encode(expectedResult), HTTPURLResponse())
        authSessionMock.validTokenReturnValue = "accessToken"

        // When
        let result: MockCodableModel = try await apiClient.get(path: "/test", params: mockParams)

        // Then
        XCTAssertEqual(result, expectedResult)
        XCTAssertEqual(httpClientMock.dataForReceivedFor?.httpMethod, "GET")
    }

    func testPostRequest() async throws {
        // Given
        let expectedRequestBody = MockCodableModel()
        let expectedResult = MockCodableModel()
        httpClientMock.dataForReturnValue = try (JSONEncoder.default.encode(expectedResult), HTTPURLResponse())
        authSessionMock.validTokenReturnValue = "accessToken"

        // When
        let result: MockCodableModel = try await apiClient.post(path: "/test", body: expectedRequestBody)

        // Then
        XCTAssertEqual(result, expectedResult)
        XCTAssertEqual(httpClientMock.dataForReceivedFor?.httpMethod, "POST")
    }
}
