import Foundation

extension DateFormatter {
    static let withFractionalSeconds: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

extension ISO8601DateFormatter {
    static let fractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}

let JSONDecoderWithDates: JSONDecoder = {
    let dec = JSONDecoder()
    dec.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)
        if let d1 = DateFormatter.withFractionalSeconds.date(from: dateString) {
            return d1
        }
        if let d2 = ISO8601DateFormatter.fractional.date(from: dateString) {
            return d2
        }
        let iso = ISO8601DateFormatter()
        if let d3 = iso.date(from: dateString) {
            return d3
        }
        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Невалидная дата: \(dateString)"
            )
        )
    }
    return dec
}()

let JSONEncoderWithDates: JSONEncoder = {
    let enc = JSONEncoder()
    enc.dateEncodingStrategy = .custom { date, encoder in
        var container = encoder.singleValueContainer()
        let s = ISO8601DateFormatter.fractional.string(from: date)
        try container.encode(s)
    }
    return enc
}()



extension Notification.Name {
    static let transactionsDidChange = Notification.Name("transactionsDidChange")
}
