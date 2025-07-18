import Foundation

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE
}

enum NetworkError: Error {
    case invalidURL
    case badStatus(code: Int, data: Data)
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)
}

final class NetworkClient {
    static let shared = NetworkClient()
    private init() {}

    private let baseURL = URL(string: "https://shmr-finance.ru/api/v1/")!
    private let token   = "gNYqkXm2wS6ZM6zn7OU7tmaA"

    func request<Req: Encodable, Res: Decodable>(
        path:   String,
        method: HTTPMethod,
        body:   Req? = nil
    ) async throws -> Res {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if method != .GET && method != .DELETE {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                req.httpBody = try JSONEncoderWithDates.encode(body)
            } catch {
                throw NetworkError.encodingError(error)
            }
        }

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw NetworkError.networkError(NSError())
        }
        guard 200...299 ~= http.statusCode else {
            throw NetworkError.badStatus(code: http.statusCode, data: data)
        }

        do {
            return try JSONDecoderWithDates.decode(Res.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}
