import Dependencies
import Foundation
import KeychainAccess

protocol TokenStorage {
    func save(_ token: AuthToken?)
    func load() -> AuthToken?
}

private let kAuthTokenKey = "kAuthTokenKey"

final class KeychainTokenStorage: TokenStorage {
    private let keychain: Keychain

    init(keychain: Keychain = Keychain(service: "com.honcharenko.mediaviewer")) {
        self.keychain = keychain
    }

    func save(_ token: AuthToken?) {
        guard let token else {
            try? keychain.remove(kAuthTokenKey)
            return
        }

        if let data = try? JSONEncoder.default.encode(token) {
            try? keychain.set(data, key: kAuthTokenKey)
        }
    }

    func load() -> AuthToken? {
        guard let data = try? keychain.getData(kAuthTokenKey) else { return nil }
        return try? JSONDecoder.default.decode(AuthToken.self, from: data)
    }
}

// MARK: - DI

extension DependencyValues {
    var tokenStorage: any TokenStorage {
        get { self[TokenStorageKey.self] }
        set { self[TokenStorageKey.self] = newValue }
    }
}

enum TokenStorageKey: DependencyKey {
    static var liveValue: any TokenStorage {
        KeychainTokenStorage()
    }
}

// MARK: - TokenStorageMock

final class TokenStorageMock: TokenStorage {
    
   // MARK: - save

    var saveCallsCount = 0
    var saveCalled: Bool {
        saveCallsCount > 0
    }
    var saveReceivedToken: AuthToken?
    var saveReceivedInvocations: [AuthToken?] = []
    var saveClosure: ((AuthToken?) -> Void)?

    func save(_ token: AuthToken?) {
        saveCallsCount += 1
        saveReceivedToken = token
        saveReceivedInvocations.append(token)
        saveClosure?(token)
    }
    
   // MARK: - load

    var loadCallsCount = 0
    var loadCalled: Bool {
        loadCallsCount > 0
    }
    var loadReturnValue: AuthToken?
    var loadClosure: (() -> AuthToken?)?

    func load() -> AuthToken? {
        loadCallsCount += 1
        return loadClosure.map({ $0() }) ?? loadReturnValue
    }
}
