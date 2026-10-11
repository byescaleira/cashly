import FeatureCore
import SwiftUI

struct FlagsSection: View {
    @Environment(\.featureFlags) private var flags

    var body: some View {
        #if DEBUG
            if let flags {
                Section {
                    ForEach(FeatureFlag.allCases) { flag in
                        Toggle(
                            flag.title,
                            isOn: Binding(
                                get: { flags.isOn(flag) }, set: { flags.override(flag, $0) }))
                    }
                    Button("Voltar aos valores padrão", systemImage: "arrow.uturn.backward") {
                        for flag in FeatureFlag.allCases { flags.override(flag, nil) }
                    }
                } header: {
                    Text("Desenvolvimento")
                } footer: {
                    Text(
                        "Grupo de lançamento deste aparelho: \(flags.bucket). Só aparece em versões de desenvolvimento."
                    )
                }
            }
        #endif
    }
}
