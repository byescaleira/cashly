//
//  CashlySystemMonitorView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 24/09/25.
//

import SwiftUI
import CashlyResource

struct CashlySystemMonitorView: CashlyView {
    @State var systemMonitor = CashlySystemMonitor()

    var body: some View {
        Section {
            CashlyVStack(spacing: .medium) {
                gaugeView
                Divider()
                    .cashlyPadding(.horizontal, .extraLarge)
                infoView
            }
            .cashlyPadding()
        } header: {
            CashlyText(CashlyL10n.string("System Monitor"))
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        } footer: {
            CashlyText(CashlyL10n.string("Monitor CPU and memory usage to track performance during model training below and ensure optimal system conditions."))
        }
        .cashly(systemMonitor: $systemMonitor)
    }

    var gaugeView: some View {
        CashlyZStack {
            Circle()
                .trim(from: .zero, to: 0.5)
                .stroke(.quaternary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(180))

            let total = systemMonitor.cpuCores.double <= .zero ? 1 : systemMonitor.cpuCores.double
            let to = (systemMonitor.cpuPercentageUsage * 0.5) / total
            Circle()
                .trim(from: .zero, to: to > 0.5 ? 0.5 : to)
                .stroke(
                    cpuColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(180))
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: systemMonitor.cpuPercentageUsage)

            CashlyVStack(spacing: .zero) {
                CashlyText(CashlyL10n.string("CPU"))
                    .cashly(font: .footnote, weight: .semibold)
                    .cashly(color: .textSecondary)

                CashlyText(systemMonitor.cpuPercentageUsage.percentage)
                    .cashly(font: .title, weight: .bold)
                    .cashly(color: .text)
                    .contentTransition(.numericText())

                CashlyText(cpuStatus.uppercased())
                    .cashly(font: .footnote, weight: .bold)
                    .cashly(color: .color(cpuColor))
                    .padding(.top, 8)
            }
            .padding(.top, -26)
        }
        .overlay {
            CashlyZStack {
                CashlyText(0.0.percentage)
                    .cashly(font: .footnote)
                    .cashly(color: .textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, -10)

                CashlyText(systemMonitor.cpuTotalPercentage.percentage)
                    .cashly(font: .footnote)
                    .cashly(color: .textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, -20)
            }
            .padding(.top, 35)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.bottom, -40)
    }

    var infoView: some View {
        CashlyHStack {
            CashlyVStack {
                CashlyText(CashlyL10n.string("Memory").uppercased())
                    .cashly(font: .caption)
                    .cashly(color: .textSecondary)
                CashlyHStack {
                    CashlyText(systemMonitor.memoryUsed)
                        .cashly(font: .headline, weight: .bold)
                        .cashly(color: .text)
                        .contentTransition(.numericText())

                    CashlyText("/  " + systemMonitor.memoryTotal)
                        .cashly(font: .headline, weight: .bold)
                        .cashly(color: .textSecondary)
                }
            }
        }
    }

    var cpuStatus: String {
        let total = systemMonitor.cpuTotalPercentage <= .zero ? 1 : systemMonitor.cpuTotalPercentage

        switch systemMonitor.cpuPercentageUsage / total {
        case 0 ..< 0.25: return "Low"
        case 0.25 ..< 0.50: return "Normal"
        case 0.50 ..< 0.75: return "High"
        default: return "Critical"
        }
    }

    var cpuColor: Color {
        let total = systemMonitor.cpuTotalPercentage <= .zero ? 1 : systemMonitor.cpuTotalPercentage

        switch systemMonitor.cpuPercentageUsage / total {
        case 0 ..< 0.25: return .green
        case 0.25 ..< 0.50: return .blue
        case 0.50 ..< 0.75: return .orange
        default: return .red
        }
    }

    static var mock: some View {
        CashlySystemMonitorView()
    }
}

#Preview {
    CashlyList {
        CashlySystemMonitorView.mock
    }
}
