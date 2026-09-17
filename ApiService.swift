import Foundation

// 与后端统一响应结构对应
struct ApiResult<T: Decodable>: Decodable {
    let code: Int
    let msg: String?
    let data: T?
}

// 设备
struct DeviceResp: Decodable, Identifiable {
    let id: String
    let name: String
    let online: Bool
    let lastHeartbeat: String?
}

// 消息
struct MessageResp: Decodable, Identifiable {
    let id: Int
    let sender: String?
    let content: String
    let status: String
    let createdAt: String

    var statusText: String {
        switch status {
        case "PLAYED": return "已播报"
        case "DELIVERED": return "已送达"
        default: return "待送达"
        }
    }
}

enum ApiError: LocalizedError {
    case server(String)
    case badURL

    var errorDescription: String? {
        switch self {
        case .server(let msg): return msg
        case .badURL: return "服务器地址无效"
        }
    }
}

// 网络层：对应后端 broadcast-server 的接口
final class ApiService {
    static let shared = ApiService()

    private var baseURL: String {
        let url = UserDefaults.standard.string(forKey: "serverURL") ?? Self.defaultURL
        return url.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("/")
            ? String(url.dropLast())
            : url
    }

    static let defaultURL = "https://78723823a408a3.lhr.life"

    // MARK: - 接口

    func devices() async throws -> [DeviceResp] {
        try await request("/api/devices")
    }

    func send(deviceId: String, sender: String, content: String) async throws -> MessageResp {
        try await request("/api/messages", method: "POST",
                          body: ["deviceId": deviceId, "sender": sender, "content": content])
    }

    func history(deviceId: String) async throws -> [MessageResp] {
        try await request("/api/devices/\(deviceId)/messages/history")
    }

    func health() async throws -> String {
        struct Health: Decodable { let status: String }
        let h: Health = try await request("/api/health")
        return h.status
    }

    // MARK: - 通用请求

    private func request<T: Decodable>(_ path: String,
                                       method: String = "GET",
                                       body: [String: Any]? = nil) async throws -> T {
        guard let url = URL(string: baseURL + path) else { throw ApiError.badURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.timeoutInterval = 15
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 500 {
            throw ApiError.server("服务器错误(\(http.statusCode))")
        }
        let result = try JSONDecoder().decode(ApiResult<T>.self, from: data)
        guard result.code == 0, let payload = result.data else {
            throw ApiError.server(result.msg ?? "未知错误")
        }
        return payload
    }
}
