import SwiftUI

// 主界面：选择设备 → 编辑内容 → 发送 → 查看记录
struct HomeView: View {
    @AppStorage("senderName") private var senderName = ""
    @AppStorage("lastDeviceId") private var lastDeviceId = ""

    @State private var devices: [DeviceResp] = []
    @State private var selectedId = ""
    @State private var content = ""
    @State private var history: [MessageResp] = []
    @State private var sending = false
    @State private var toast: String?
    @State private var loadError: String?

    private let quickPhrases = ["请相关人员速到前台", "请注意设备运行状态", "请到会议室开会", "有客户来访，请接待", "紧急情况，请立即处理"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    senderCard
                    deviceCard
                    contentCard
                    sendButton
                    historyCard
                }
                .padding(12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("喊话中心")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .task { await refreshAll() }
            .refreshable { await refreshAll() }
            .overlay(alignment: .bottom) {
                if let toast {
                    Text(toast)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.black.opacity(0.78), in: Capsule())
                        .padding(.bottom, 40)
                        .transition(.opacity)
                }
            }
        }
    }

    // MARK: - 我的称呼

    private var senderCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("我的称呼").font(.headline)
            TextField("例如：张三 / 一号窗口", text: $senderName)
                .padding(10)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        }
        .cardStyle()
    }

    // MARK: - 设备选择

    private var deviceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("选择设备").font(.headline)
                Spacer()
                Button { Task { await refreshAll() } } label: { Text("刷新") }
                    .font(.subheadline)
            }
            if devices.isEmpty {
                Text(loadError ?? "暂无设备，请先启动电脑端客户端")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                    ForEach(devices) { d in
                        deviceChip(d)
                    }
                }
            }
        }
        .cardStyle()
    }

    private func deviceChip(_ d: DeviceResp) -> some View {
        Button {
            if !d.online {
                showToast("该设备当前离线")
            }
            selectedId = d.id
            lastDeviceId = d.id
            Task { await loadHistory() }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(d.online ? Color.green : Color.gray.opacity(0.4))
                    .frame(width: 8, height: 8)
                Text(d.online ? d.name : "\(d.name)（离线）")
                    .font(.subheadline)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(selectedId == d.id ? Color.blue.opacity(0.12) : Color(.secondarySystemGroupedBackground))
            .foregroundStyle(selectedId == d.id ? .blue : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 999)
                    .strokeBorder(selectedId == d.id ? Color.blue : Color.clear, lineWidth: 1.5)
            )
            .clipShape(Capsule())
        }
    }

    // MARK: - 内容编辑

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("喊话内容").font(.headline)
                Spacer()
                Text("\(content.count)/500").font(.caption).foregroundStyle(.secondary)
            }
            TextField("输入要喊话的内容，电脑端将语音播报", text: $content, axis: .vertical)
                .lineLimit(3...6)
                .padding(10)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))

            Text("快捷短语（点击填入）").font(.caption).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 6)], spacing: 6) {
                ForEach(quickPhrases, id: \.self) { p in
                    Button { content = p } label: {
                        Text(p)
                            .font(.caption)
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - 发送

    private var sendButton: some View {
        Button(action: { Task { await send() } }) {
            HStack {
                if sending { ProgressView().tint(.white) }
                Text(buttonText)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(15)
        }
        .foregroundStyle(.white)
        .background(canSend ? Color.blue : Color.blue.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
        .disabled(!canSend)
    }

    private var canSend: Bool { !selectedId.isEmpty && !content.trimmingCharacters(in: .whitespaces).isEmpty && !sending }

    private var buttonText: String {
        if sending { return "发送中…" }
        if selectedId.isEmpty { return "选择设备后发送" }
        if content.trimmingCharacters(in: .whitespaces).isEmpty { return "输入喊话内容" }
        return "发送喊话 →"
    }

    // MARK: - 历史记录

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("发送记录").font(.headline)
                Spacer()
                if !selectedId.isEmpty {
                    Button { Task { await loadHistory() } } label: { Text("刷新") }
                        .font(.subheadline)
                }
            }
            if history.isEmpty {
                Text(selectedId.isEmpty ? "选择设备后显示发送记录" : "暂无记录")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            } else {
                ForEach(history) { m in
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(m.content).font(.subheadline)
                            Text("\(m.sender ?? "") · \(m.createdAt)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(m.statusText)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(tagColor(m.status).opacity(0.15), in: Capsule())
                            .foregroundStyle(tagColor(m.status))
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
            }
        }
        .cardStyle()
    }

    private func tagColor(_ status: String) -> Color {
        switch status {
        case "PLAYED": return .green
        case "DELIVERED": return .blue
        default: return .orange
        }
    }

    // MARK: - 动作

    private func refreshAll() async {
        do {
            devices = try await ApiService.shared.devices() ?? []
            loadError = nil
            if selectedId.isEmpty, let restored = devices.first(where: { $0.id == lastDeviceId }) {
                selectedId = restored.id
            }
            if !selectedId.isEmpty { await loadHistory() }
        } catch {
            loadError = "连接失败：\(error.localizedDescription)"
        }
    }

    private func loadHistory() async {
        guard !selectedId.isEmpty else { return }
        history = (try? await ApiService.shared.history(deviceId: selectedId)) ?? []
    }

    private func send() async {
        sending = true
        defer { sending = false }
        do {
            _ = try await ApiService.shared.send(deviceId: selectedId,
                                                 sender: senderName.trimmingCharacters(in: .whitespaces),
                                                 content: content.trimmingCharacters(in: .whitespaces))
            content = ""
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showToast("发送成功，电脑端将播报")
            await loadHistory()
        } catch {
            showToast("发送失败：\(error.localizedDescription)")
        }
    }

    private func showToast(_ msg: String) {
        withAnimation { toast = msg }
        Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            withAnimation { toast = nil }
        }
    }
}

// 卡片通用样式
extension View {
    func cardStyle() -> some View {
        self
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}
