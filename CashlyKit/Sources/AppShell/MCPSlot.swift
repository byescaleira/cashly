import FeatureCore
import FeatureGuides
import FeatureMCP
import SwiftUI

public struct MCPSettingsSlot: View {
    @Environment(MCPModel.self) private var mcp: MCPModel?
    @Environment(\.featureFlags) private var flags

    public init() {}

    public var body: some View {
        if let mcp, flags?.isOn(.mcpServer) != false { MCPSettingsSection().environment(mcp) }
    }
}

struct MCPImportPresenter: ViewModifier {
    @Environment(MCPModel.self) private var mcp: MCPModel?
    @State private var shown: MCPModel.Prompt?
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .sheet(item: $shown, onDismiss: dismissed) { prompt in
                if let mcp {
                    switch prompt {
                    case .connection(let request):
                        ConnectionApprovalScreen(request: request).environment(mcp)
                    case .importing(let request):
                        ExternalImportScreen(preview: request.preview, source: request.source) {
                            mcp.finish(request.id, imported: $0)
                        }
                    }
                }
            }
            .onChange(of: mcp?.prompt?.id, initial: true) { present() }
    }

    private func dismissed() {
        isVisible = false
        Task { present() }
    }

    private func present() {
        let prompt = mcp?.prompt
        if isVisible {
            if prompt?.id != shown?.id { shown = nil }
            return
        }
        guard let prompt else { return }
        shown = prompt
        isVisible = true
    }
}
