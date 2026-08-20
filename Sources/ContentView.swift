import SwiftUI

struct ContentView: View {
    @StateObject private var model = CleanerViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    statusCard
                    memoryCard
                    cleanButton
                    historyCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("一键清理")
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("设备状态").font(.title2.bold())
                Text("安全结束可关闭的用户应用")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 34)).foregroundStyle(.blue)
        }
        .padding(.top, 8)
    }

    private var statusCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "memorychip").font(.title2).foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 4) {
                Text("运行状态").font(.headline)
                Text(model.status).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            if model.isCleaning { ProgressView() }
        }
        .padding(18).background(.background, in: RoundedRectangle(cornerRadius: 18))
    }

    private var memoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("实时内存", systemImage: "memorychip").font(.headline)
                Spacer()
                Text(model.memory?.usedText ?? "读取中…")
                    .font(.headline.monospacedDigit())
            }
            ProgressView(value: model.memory?.fraction ?? 0)
                .tint((model.memory?.fraction ?? 0) > 0.85 ? .orange : .blue)
            HStack {
                Text("已用 / 总内存：\(model.memory?.totalText ?? "—")")
                Spacer()
                Text("可用：\(model.memory?.availableText ?? "—")")
            }
            .font(.caption).foregroundStyle(.secondary)
            Text("数据为设备级内存统计；iOS 不向第三方 App 提供其他应用的逐进程内存详情。")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18).background(.background, in: RoundedRectangle(cornerRadius: 18))
    }

    private var cleanButton: some View {
        Button { model.clean() } label: {
            Label(model.isCleaning ? "正在清理…" : "一键清理", systemImage: "sparkles")
                .font(.title3.bold()).frame(maxWidth: .infinity).padding(.vertical, 20)
        }
        .buttonStyle(.borderedProminent).controlSize(.large)
        .disabled(model.isCleaning)
        .animation(.easeInOut, value: model.isCleaning)
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("清理记录", systemImage: "clock.arrow.circlepath").font(.headline)
            if model.logs.isEmpty {
                Text("暂无记录").font(.subheadline).foregroundStyle(.secondary)
            } else {
                ForEach(model.logs) { log in
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text(log.text).font(.subheadline)
                        Spacer()
                        Text(log.date, style: .time).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18).background(.background, in: RoundedRectangle(cornerRadius: 18))
    }
}
