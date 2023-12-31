import Foundation

struct Session: Codable, Equatable {
    let sessionId: String
    let accountId: String
    let clientIp: String
    let clientCountry: String
    let clientCountryIso: String
    let clientCity: String
    let clientAgent: String
    let verifications: [String]
    let createdAt: String
    let expiryAt: String
    let lastUse: String
    let browser: Browser
}

struct Browser: Codable, Equatable {
    let bot: Bool
    let browser: String
    let browserVersion: String
    let engine: String
    let engineVersion: String
    let mobile: Bool
    let os: OS
    let platform: String
}

struct OS: Codable, Equatable {
    let fullName: String
    let name: String
    let version: String
}

struct Account: Codable, Equatable {
    let accountId: String
    let accountType: String
    let email: String
    let emailVerified: Bool
    let phone: String
    let totpVerified: Bool
    let password: String?  // Change the type as needed
    let createdAt: String
    let partnerId: String?  // Change the type as needed
    let autoGenerated: Bool
}

struct Profile: Codable, Equatable {
    let profileId: String
    let accountId: String
    let profileType: String
    let firstName: String
    let lastName: String
    let location: String
    let gender: String
    let email: String
    let avatarUrl: String?  // Change the type as needed
    let joinedAt: String
    let onlineStatus: String
    let reviewsCount: Int
    let isPartner: Bool
    let complainsNum: Int
}

struct VerifiedInfo: Codable, Equatable {
    let emails: [String]
    let phones: [String]
    let docs: [String]
}

struct SessionInfo: Codable, Equatable {
    let session: Session
    let account: Account
    let profiles: [Profile]
    let verified: VerifiedInfo
}

extension SessionInfo {
    static var mock: SessionInfo {
        let jsonData = """
        {
        "session": {
        "session_id": "sess-18ba1ab3c34",
        "account_id": "afe0f9e4-4164-4fc9-bf8f-3fd8c85ae802",
        "client_ip": "147.182.169.0",
        "client_country": "United States",
        "client_country_iso": "US",
        "client_city": "North Bergen",
        "client_agent": "RESTSocketExample/1 CFNetwork/1474 Darwin/22.6.0",
        "verifications": [
        "creds"
        ],
        "created_at": "2023-11-05T22:47:15.760Z",
        "expiry_at": "2023-11-06T22:47:15.760Z",
        "last_use": "2023-11-05T22:47:15.760Z",
        "device": null,
        "browser": {
        "bot": false,
        "browser": "RESTSocketExample",
        "browser_version": "1",
        "engine": "CFNetwork",
        "engine_version": "1474",
        "mobile": false,
        "os": {
          "full_name": "",
          "name": "",
          "version": ""
        },
        "platform": ""
        }
        },
        "account": {
        "account_id": "afe0f9e4-4164-4fc9-bf8f-3fd8c85ae802",
        "account_type": "user",
        "email": "hello@karta.com",
        "email_verified": false,
        "phone": "",
        "totp_verified": false,
        "2fa_method": "email_2fa",
        "password": null,
        "created_at": "2019-11-06T14:45:38.515Z",
        "partner_id": null,
        "auto_generated": false
        },
        "profiles": [
        {
        "profile_id": "4e8a1831-2b78-4c8d-9fbf-aa4172e017dc",
        "account_id": "afe0f9e4-4164-4fc9-bf8f-3fd8c85ae802",
        "profile_type": "guest",
        "first_name": "Jimmy",
        "last_name": "Song",
        "location": "",
        "gender": "unknown_gender",
        "phone_country": null,
        "phone_number": null,
        "email": "hello@karta.com",
        "avatar_url": null,
        "langs_spoken_names": [

        ],
        "joined_at": "2019-11-06T14:45:38.517Z",
        "online_status": "online",
        "guest_score": null,
        "reviews_count": 0,
        "is_partner": false,
        "billing_info": {

        },
        "country": null,
        "nationality": null,
        "complains_num": 0
        }
        ],
        "verified": {
        "emails": [

        ],
        "phones": [

        ],
        "docs": [

        ]
        }
        }
        """.data(using: .utf8)

        return try! JSONDecoder.default.decode(SessionInfo.self, from: jsonData!)
    }
}
