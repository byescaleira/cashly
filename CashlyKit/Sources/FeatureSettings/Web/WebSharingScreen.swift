import CashlyDesignSystem
import CashlyWeb
import FeatureCore
import SwiftUI

struct WebSharingScreen: View {
    @Environment(WebSharingModel.self) private var web
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        @Bindable var web = web
        SettingsPage("Cashly on the Web") {
            ProOnly {
                WebHeroSection()
                if web.sessions.isEmpty { WebStepsSection() }
                WebScanSection()
            }
            WebSessionsSection()
            ProShowcaseSection(.web)
        }
        .animation(reduceMotion ? nil : .smooth, value: web.sessions.map(\.id))
        .sheet(item: $web.confirmingDisconnect) { session in
            WebDisconnectScreen(session: session).environment(web)
        }
        #if os(iOS)
            .sheet(isPresented: $web.isScanning) { WebScannerScreen().environment(web) }
        #endif
        .errorAlert($web.error)
        .onAppear { web.pruneExpired() }
    }
}

private struct WebHeroSection: View {
    @Environment(WebSharingModel.self) private var web

    var body: some View {
        Section {
            VStack(spacing: .spaceM) {
                CashlyAnimationView(.web).frame(maxWidth: 260)
                VStack(spacing: .space2XS) {
                    Text(verbatim: web.heroTitle)
                        .font(.titleMedium)
                        .contentTransition(.numericText(value: web.connectedCount))
                    Text(verbatim: web.heroMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .contentTransition(.opacity)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spaceS)
            .accessibilityElement(children: .combine)
        }
    }
}

private struct WebStepsSection: View {
    @Environment(WebSharingModel.self) private var web

    var body: some View {
        Section {
            ForEach(Array(web.steps.enumerated()), id: \.offset) { index, step in
                SettingsStepRow(number: index + 1, text: step)
            }
        } header: {
            Text("How It Works").sectionTitle()
        } footer: {
            Text(
                "The summary is encrypted on this device for that browser only. Our bridge keeps it for up to 24 hours and can't read it. Only the current profile and month are sent."
            )
        }
    }
}

private struct WebScanSection: View {
    @Environment(WebSharingModel.self) private var web
    @Environment(\.appTint) private var appTint

    var body: some View {
        if web.isScannerSupported {
            Section {
                Button {
                    Task { await web.startScanning() }
                } label: {
                    IconRow(
                        "Scan QR Code", detail: "Point at the code on the computer screen.",
                        symbol: "qrcode.viewfinder", color: appTint)
                }
            }
        }
    }
}

private struct WebSessionsSection: View {
    @Environment(WebSharingModel.self) private var web

    var body: some View {
        if !web.sessions.isEmpty {
            Section {
                ForEach(web.sessions) { session in
                    WebSessionRow(session: session)
                    Button(role: .destructive) {
                        web.confirmingDisconnect = session
                    } label: {
                        IconRow(
                            "Disconnect", symbol: "xmark", color: .negative,
                            titleColor: .negative)
                    }
                    .disabled(web.disconnectingID == session.id)
                    .accessibilityLabel(web.disconnectLabel(for: session))
                }
            } header: {
                Text("Connected Computers").sectionTitle()
            } footer: {
                Text(verbatim: web.sessionsFooter)
            }
        }
    }
}

private struct WebSessionRow: View {
    @Environment(WebSharingModel.self) private var web
    @Environment(\.appTint) private var appTint
    let session: WebSession

    var body: some View {
        TimelineView(.everyMinute) { context in
            VStack(alignment: .leading, spacing: .spaceS) {
                HStack(spacing: .spaceS) {
                    IconRow(
                        verbatim: web.title(of: session),
                        detail: web.detail(of: session, at: context.date),
                        symbol: "laptopcomputer", color: appTint)
                    Chip(
                        web.status(of: session, at: context.date),
                        color: web.statusColor(of: session)
                    )
                    .fixedSize()
                }
                SettingsBar(
                    value: web.remainingFraction(of: session, at: context.date), color: appTint)
            }
            .accessibilityElement(children: .combine)
        }
    }
}
