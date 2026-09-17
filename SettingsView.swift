import SwiftUI

// 设置页：配置服务器地址（默认连你本机的外网地址）
struct SettingsView: View {
    @AppStorage("serverURL") private var serverURL = ApiService.defaultURL
    @State private var testing = false
    @State private var testResult: (Bool, String)?

    var body: some View {
        Form {
            Section {
                TextField("服务器地址", text: $serverURL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(.system(.body, design: .monospaced))
            } header: {
                Text("服务器地址")
            } footer: {
                Text("填你电脑的外网地址（如 \(ApiService.defaultURL)）或局域网地址（如 http://192.168.99.250:8090）")
            }

            Section {
                Button {
                    Task { await test() }
                } label: {
                    HStack {
                        if testing { ProgressView() }
                        Text("测试连接")
                    }
                }
                if let r = testResult {
                    Label(r.1, systemImage: r.0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(r.0 ? Color.green : Color.red)
                        .font(.subheadline)
                }
            } header: {
                Text("连接测试")
            }

            Section {
                Button("恢复默认地址", role: .destructive) {
                    serverURL = ApiService.defaultURL
                    testResult = nil
                }
            }
        }
        .navigationTitle("设置")
    }

    private func test() async {
        testing = true
        defer { testing = false }
        do {
            let status = try await ApiService.shared.health()
            testResult = (status == "UP", "连接成功，服务器状态：\(status)")
        } catch {
            testResult = (false, "连接失败：\(error.localizedDescription)")
        }
    }
}
