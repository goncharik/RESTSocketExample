import Foundation

struct AuthToken: Codable, Equatable {
    var token: String
    var expiration: Date
    var serverTime: Date
    var expiresIn: Int {
        Int(expiration.timeIntervalSince(serverTime))
    }
    var createdAt: Date?

    var isValid: Bool {
        guard let createdAt else { return false }

        let now = Date()
        return createdAt.addingTimeInterval(TimeInterval(expiresIn)) > now
    }
}
