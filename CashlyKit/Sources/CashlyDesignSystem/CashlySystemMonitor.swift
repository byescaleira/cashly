//
//  CashlySystemMonitor.swift
//  CashlyKit
//
//  CPU + memory probe via Mach task APIs. The ViewModifier
//  refreshes a binding once per second and dispatches updates
//  through withAnimation(.bouncy) on the main actor.
//

import SwiftUI
#if canImport(Darwin)
import Darwin
import Foundation
#endif

public struct CashlySystemMonitor: Sendable, Equatable {
    public var cpuPercentageUsage: Double
    public var cpuTotalPercentage: Double
    public var cpuUsage: Int
    public var cpuCores: Int

    public var memoryPercentageUsage: Double
    public var memoryTotalPercentage: Double
    public var memoryUsed: String
    public var memoryTotal: String

    public init(
        cpuPercentageUsage: Double = .zero,
        cpuTotalPercentage: Double = .zero,
        cpuUsage: Int = .zero,
        cpuCores: Int = .zero,
        memoryPercentageUsage: Double = .zero,
        memoryTotalPercentage: Double = .zero,
        memoryUsed: String = "",
        memoryTotal: String = ""
    ) {
        self.cpuPercentageUsage = cpuPercentageUsage
        self.cpuTotalPercentage = cpuTotalPercentage
        self.cpuUsage = cpuUsage
        self.cpuCores = cpuCores
        self.memoryPercentageUsage = memoryPercentageUsage
        self.memoryTotalPercentage = memoryTotalPercentage
        self.memoryUsed = memoryUsed
        self.memoryTotal = memoryTotal
    }
}

struct CashlySystemMonitorModifier: ViewModifier {
    @Binding var systemMonitor: CashlySystemMonitor
    private let timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()

    init(systemMonitor: Binding<CashlySystemMonitor>) {
        self._systemMonitor = systemMonitor
    }

    func body(content: Content) -> some View {
        content.onReceive(timer) { _ in
            Task { @MainActor in
                guard let cpu = CashlySystemMonitorProbe.cpu(),
                      let memory = CashlySystemMonitorProbe.memory()
                else { return }
                withAnimation(.bouncy) {
                    systemMonitor = CashlySystemMonitor(
                        cpuPercentageUsage: cpu.percentage,
                        cpuTotalPercentage: cpu.total,
                        cpuUsage: cpu.usage,
                        cpuCores: cpu.cores,
                        memoryPercentageUsage: memory.percentage,
                        memoryTotalPercentage: memory.total,
                        memoryUsed: memory.used,
                        memoryTotal: memory.totalString
                    )
                }
            }
        }
    }
}

public extension View {
    func cashly(systemMonitor: Binding<CashlySystemMonitor>) -> some View {
        modifier(CashlySystemMonitorModifier(systemMonitor: systemMonitor))
    }
}

enum CashlySystemMonitorProbe {
    struct CPUSample { let percentage: Double; let total: Double; let usage: Int; let cores: Int }
    struct MemorySample { let percentage: Double; let total: Double; let used: String; let totalString: String }

    static func cpu() -> CPUSample? {
        var threadsList: thread_act_array_t?
        var threadsCount = mach_msg_type_number_t(0)
        let threadsResult = task_threads(mach_task_self_, &threadsList, &threadsCount)
        guard threadsResult == KERN_SUCCESS, let threadsList else { return nil }

        var totalUsage: Double = .zero
        for index in 0 ..< Int(threadsCount) {
            var info = thread_basic_info()
            var infoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
            let result = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    thread_info(threadsList[index], thread_flavor_t(THREAD_BASIC_INFO), $0, &infoCount)
                }
            }
            guard result == KERN_SUCCESS else { continue }
            if info.flags & TH_FLAGS_IDLE == 0 {
                totalUsage += Double(info.cpu_usage) / Double(TH_USAGE_SCALE)
            }
        }
        vm_deallocate(
            mach_task_self_,
            vm_address_t(UInt(bitPattern: threadsList)),
            vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride)
        )

        let cores = ProcessInfo.processInfo.activeProcessorCount
        let adjusted = totalUsage * Double(cores)
        let totalPct = Double(cores)
        return CPUSample(
            percentage: adjusted / totalPct,
            total: totalPct,
            usage: Int(adjusted.rounded()),
            cores: cores
        )
    }

    static func memory() -> MemorySample? {
        var info = task_vm_info()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size / MemoryLayout<integer_t>.size)
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard kerr == KERN_SUCCESS else { return nil }

        let footprint = Int64(info.phys_footprint)
        let totalBytes = Int64(ProcessInfo.processInfo.physicalMemory)
        guard totalBytes > 0 else { return nil }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return MemorySample(
            percentage: Double(footprint) / Double(totalBytes),
            total: 1,
            used: formatter.string(fromByteCount: footprint),
            totalString: formatter.string(fromByteCount: totalBytes)
        )
    }
}
