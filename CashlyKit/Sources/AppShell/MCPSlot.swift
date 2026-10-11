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

    func body(content: Content) -> some View {
        content
            .sheet(
                item: Binding(
                    get: { mcp?.connection }, set: { if $0 == nil { mcp?.connection = nil } })
            ) {
                request in
                if let mcp { ConnectionApprovalScreen(request: request).environment(mcp) }
            }
            .sheet(
                item: Binding(get: { mcp?.pending }, set: { if $0 == nil { mcp?.pending = nil } })
            ) { request in
                ExternalImportScreen(preview: request.preview, source: request.source) { imported in
                    mcp?.finish(request.id, imported: imported)
                }
            }
    }
}
