import CashlyDesignSystem
import CashlyDomain
import SwiftUI

struct LanguageScreen: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        SettingsPage("Language") {
            LanguagePreviewSection()
            LanguageListSection()
        }
        .sensoryFeedback(.selection, trigger: settings.language)
    }
}

private struct LanguagePreviewSection: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.appTint) private var appTint

    var body: some View {
        let preview = settings.languagePreview(of: settings.language)
        Section {
            VStack(alignment: .leading, spacing: .space2XS) {
                Text(verbatim: preview.date).font(.subheadline).foregroundStyle(.secondary)
                Text(verbatim: preview.amount).font(.amountTitle).amountLine()
                Text(verbatim: preview.sentence).font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, .space2XS)
            .id(settings.language)
            .transition(.opacity)
        } header: {
            SettingsHero {
                LanguageGlyph(language: settings.language, size: .badgeXL)
                Text(verbatim: settings.shortName(of: settings.language))
                    .font(.titleLarge)
                    .foregroundStyle(Color.primary)
                    .contentTransition(.opacity)
                Chip(
                    settings.language == .system ? "Follows the device" : "Chosen in Cashly",
                    color: appTint, shape: .capsule)
            }
        } footer: {
            Text("Dates, numbers and amounts follow the language you choose.")
        }
        .animation(.smooth, value: settings.language)
    }
}

private struct LanguageListSection: View {
    var body: some View {
        Section {
            ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element) { index, language in
                LanguageRow(language: language).settingsReveal(index)
            }
        } footer: {
            Text(
                "Cashly changes language right away. System texts, such as the keyboard and date pickers, follow the next time the app opens."
            )
        }
    }
}

private struct LanguageRow: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.appTint) private var appTint
    let language: AppLanguage

    var body: some View {
        let isSelected = settings.language == language
        Button {
            settings.language = language
        } label: {
            HStack(spacing: .spaceM) {
                LanguageGlyph(language: language, size: .badgeS + .space2XS)
                VStack(alignment: .leading, spacing: .spaceHairline) {
                    Text(verbatim: language.nativeName).foregroundStyle(Color.primary)
                    if let detail = settings.languageDetail(of: language) {
                        Text(verbatim: detail).font(.footnote).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: .spaceS)
                if language != .system, settings.deviceLanguage() == language {
                    Chip("Device", color: .secondary)
                }
                SelectionMark(isSelected: isSelected)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct LanguageGlyph: View {
    @Environment(\.appTint) private var appTint
    let language: AppLanguage
    let size: CGFloat

    var body: some View {
        Group {
            if language == .system {
                Image(systemName: "globe").font(.icon(size > .badgeL ? .l : .s, weight: .medium))
            } else {
                Text(verbatim: language.glyph)
                    .font(size > .badgeL ? .titleMedium : .callout.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .foregroundStyle(appTint)
        .frame(width: size, height: size)
        .background(appTint.opacity(.opacityTint), in: .rect(cornerRadius: .radiusS))
        .accessibilityHidden(true)
    }
}
