import Foundation

struct AppEnv {
    var baseUrl: String
    var socketUrl: String
}

// MARK: - Live value

extension AppEnv {
    static var live: Self {
        Self(
            baseUrl: "https://dev.karta.com/api/",
            socketUrl: "wss://ws.blockchain.info/inv"
        )
    }
}

// MARK: - Mock value

extension AppEnv {
    static var mock: Self {
        Self(
            baseUrl: "https://baseUrl",
            socketUrl: "https://socketUrl"
        )
    }
}
