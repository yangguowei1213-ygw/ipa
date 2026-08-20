import SwiftUI

struct SettingsView: View {
    @State private var words = ""
    @State private var saved = false
    private let store = UserDefaults(suiteName: "group.com.app.keyboard")

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("iOS 26 键盘", systemImage: "keyboard.fill")
                        .font(.title2.bold())
                    Text("轻量、隐私优先的系统风格输入法。请在设置 → 通用 → 键盘 → 键盘中添加并启用。")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Section("自定义词库") {
                    TextField("每行输入一个词语", text: $words, axis: .vertical)
                        .lineLimit(5...10)
                    Button {
                        let list = words.split(whereSeparator: \.isNewline).map(String.init)
                        store?.set(list, forKey: "customWords")
                        saved = true
                    } label: {
                        Label(saved ? "已保存" : "保存词库", systemImage: "checkmark.circle")
                    }
                }
                Section("隐私与限制") {
                    Text("输入法不会遍历或终止其他进程。密码框会由 iOS 自动切回安全键盘；完全访问权限仅在你主动开启后可用于共享词库等功能。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("键盘设置")
        }
    }
}
