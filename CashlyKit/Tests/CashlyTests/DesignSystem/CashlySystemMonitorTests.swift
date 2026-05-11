//
//  CashlySystemMonitorTests.swift
//  CashlyKit
//
//  Tests for the value-type surface. The Mach-API probe itself runs
//  inside a 1Hz timer modifier on real device/simulator; here we only
//  verify the data shape + Equatable behavior.
//

import Testing
import CashlyDesignSystem

@Suite("CashlySystemMonitor", .tags(.unit, .ui, .local))
struct CashlySystemMonitorTests {
    @Test("default init produces zeroed values")
    func defaultsAreZero() {
        let monitor = CashlySystemMonitor()
        #expect(monitor.cpuPercentageUsage == 0)
        #expect(monitor.cpuTotalPercentage == 0)
        #expect(monitor.cpuUsage == 0)
        #expect(monitor.cpuCores == 0)
        #expect(monitor.memoryPercentageUsage == 0)
        #expect(monitor.memoryTotalPercentage == 0)
        #expect(monitor.memoryUsed == "")
        #expect(monitor.memoryTotal == "")
    }

    @Test("explicit init wires every field")
    func explicitInit() {
        let monitor = CashlySystemMonitor(
            cpuPercentageUsage: 0.42,
            cpuTotalPercentage: 4,
            cpuUsage: 168,
            cpuCores: 4,
            memoryPercentageUsage: 0.65,
            memoryTotalPercentage: 1,
            memoryUsed: "5.2 GB",
            memoryTotal: "8 GB"
        )
        #expect(monitor.cpuPercentageUsage == 0.42)
        #expect(monitor.cpuTotalPercentage == 4)
        #expect(monitor.cpuUsage == 168)
        #expect(monitor.cpuCores == 4)
        #expect(monitor.memoryPercentageUsage == 0.65)
        #expect(monitor.memoryTotalPercentage == 1)
        #expect(monitor.memoryUsed == "5.2 GB")
        #expect(monitor.memoryTotal == "8 GB")
    }

    @Test("Equatable: same fields == ; different fields !=")
    func equatable() {
        let a = CashlySystemMonitor(cpuUsage: 10)
        let b = CashlySystemMonitor(cpuUsage: 10)
        let c = CashlySystemMonitor(cpuUsage: 11)
        #expect(a == b)
        #expect(a != c)
    }
}
