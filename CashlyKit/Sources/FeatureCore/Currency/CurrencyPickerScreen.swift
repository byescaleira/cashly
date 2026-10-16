import CashlyDesignSystem
import CashlyDomain
import SwiftUI

public struct CurrencyPickerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    let title: LocalizedStringKey
    let codes: [String]
    let suggested: [String]
    let locked: Set<String>
    let lockedReason: LocalizedStringKey?
    let selection: String
    let select: (String) -> Void

    public init(
        _ title: LocalizedStringKey, codes: [String], suggested: [String],
        locked: Set<String> = [], lockedReason: LocalizedStringKey? = nil, selection: String,
        select: @escaping (String) -> Void
    ) {
        self.title = title
        self.codes = codes
        self.suggested = suggested
        self.locked = locked
        self.lockedReason = lockedReason
        self.selection = selection
        self.select = select
    }

    public var body: some View {
        let groups = CurrencyText.sections(codes: codes, suggested: suggested, query: query)
        List {
            if groups.isEmpty {
                ContentUnavailableView.search(text: query)
            }
            ForEach(groups) { group in
                Section {
                    ForEach(group.codes, id: \.self) { code in
                        CurrencyPickerRow(
                            code: code, isSelected: code == selection,
                            isLocked: locked.contains(code)
                        ) { choose(code) }
                    }
                } header: {
                    if let title = group.title { Text(title).sectionTitle() }
                } footer: {
                    if let lockedReason, !locked.isEmpty, group == groups.first {
                        Label(lockedReason, systemImage: "lock")
                    }
                }
            }
        }
        .fontDesign(.rounded)
        .readableWidth()
        .navigationTitle(title)
        #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .searchable(text: $query, prompt: Text("Search Currencies"))
    }

    private func choose(_ code: String) {
        select(code)
        dismiss()
    }
}

private struct CurrencyPickerRow: View {
    let code: String
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .spaceM) {
                CurrencySymbolBadge(symbol: CurrencyText.symbol(code), size: .badgeS + .space2XS)
                VStack(alignment: .leading, spacing: .spaceHairline) {
                    Text(verbatim: CurrencyText.name(code)).foregroundStyle(Color.primary)
                    Text(verbatim: code)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: .spaceS)
                if isLocked {
                    Image(systemName: "lock")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                } else {
                    SelectionMark(isSelected: isSelected)
                }
            }
            .contentShape(.rect)
            .opacity(isLocked ? .opacityStrong : 1)
        }
        .buttonStyle(.plain)
        .accessibilityValue(isLocked ? Text("Locked") : Text(verbatim: ""))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
