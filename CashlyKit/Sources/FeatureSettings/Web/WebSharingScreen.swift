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
                CashlyAnimationView(.connect).frame(maxWidth: 260)
                VStack(spacing: .space2XS) {
                    Text(verbatim: web.heroTitle)
                        .font(.titleMedium)
                        .contentTransition(.numericText())
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
    @Environment(\.appTint) private var appTint

    var body: some View {
        Section {
            IconRow(
                verbatim: web.openPageTitle, detail: web.openPageDetail,
                symbol: "laptopcomputer", color: appTint)
            IconRow(
                title: Text("Scan the QR Code"), detail: Text(verbatim: web.scanStepDetail),
                symbol: "qrcode.viewfinder", color: .companion)
            IconRow(
                "Confirm in Cashly",
                detail: "Your month opens there in a moment and stays up to date for 24 hours.",
                symbol: "checkmark", color: appTint)
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
                Text(
                    "Disconnecting deletes the summary from the bridge right away, and that browser goes back to the QR code."
                )
            }
        }
    }
}

private struct WebSessionRow: View {
    @Environment(WebSharingModel.self) private var web
    let session: WebSession

    var body: some View {
        TimelineView(.everyMinute) { context in
            VStack(alignment: .leading, spacing: .spaceS) {
                IconRow(
                    verbatim: web.title(of: session),
                    detail: web.detail(of: session, at: context.date),
                    symbol: "laptopcomputer", color: RetroColor.turquoise.color)
                SettingsBar(
                    value: web.remainingFraction(of: session, at: context.date),
                    color: RetroColor.turquoise.color)
            }
        }
    }
}
