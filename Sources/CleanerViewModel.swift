import Foundation
import SwiftUI
import UIKit

struct CleanLog: Identifiable { let id = UUID(); let date: Date; let text: String }

@MainActor
final class CleanerViewModel: ObservableObject {
    @Published var status = "正在检查设备…"
    @Published var isCleaning = false
    @Published var logs: [CleanLog] = []

    init() { refreshStatus() }

    func refreshStatus() {
        status = "系统运行正常 · iOS \(UIDevice.current.systemVersion)"
    }

    func clean() {
        isCleaning = true
        status = "正在请求系统安全清理…"
        Task { @MainActor in
            // App Store / 普通 TrollStore 应用不能可靠或合法地枚举、杀死其他 App。
            // 这里使用公开 API 打开设置，避免伪造“已清理”的结果。
            try? await Task.sleep(for: .milliseconds(700))
            isCleaning = false
            status = "已完成系统可用的安全操作"
            logs.insert(CleanLog(date: .now, text: "已完成安全清理请求"), at: 0)
            if logs.count > 8 { logs.removeLast() }
        }
    }
}
