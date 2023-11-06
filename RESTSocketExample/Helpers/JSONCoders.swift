import Foundation

extension JSONEncoder {
    static let `default`: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom({ date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode("\(date.timeIntervalSince1970)")
        })
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
}

extension JSONDecoder {
    static let `default`: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom({ decoder in
            let data = try decoder.singleValueContainer().decode(String.self)
            return Date(timeIntervalSince1970: Double(data) ?? 0)
        })
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}
