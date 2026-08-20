import Foundation
import Darwin
import MachO

struct MemorySnapshot {
    let usedBytes: UInt64
    let totalBytes: UInt64
    let availableBytes: UInt64

    var usedText: String { ByteCountFormatter.string(fromByteCount: Int64(usedBytes), countStyle: .memory) }
    var totalText: String { ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .memory) }
    var availableText: String { ByteCountFormatter.string(fromByteCount: Int64(availableBytes), countStyle: .memory) }
    var fraction: Double {
        guard totalBytes > 0 else { return 0 }
        return min(max(Double(usedBytes) / Double(totalBytes), 0), 1)
    }
}

enum MemoryMonitor {
    static func snapshot() -> MemorySnapshot? {
        var statistics = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &statistics) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        let pageSize = UInt64(vm_kernel_page_size)
        let free = UInt64(statistics.free_count) * pageSize
        let inactive = UInt64(statistics.inactive_count) * pageSize
        let purgeable = UInt64(statistics.purgeable_count) * pageSize
        let total = UInt64(ProcessInfo.processInfo.physicalMemory)
        let available = min(total, free + purgeable)
        let used = total > available ? total - available : 0
        _ = inactive // Kept available for future detailed diagnostics.
        return MemorySnapshot(usedBytes: used, totalBytes: total, availableBytes: available)
    }
}
