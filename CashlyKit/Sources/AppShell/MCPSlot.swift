import FeatureGuides
import FeatureMCP
import SwiftUI

public struct MCPSettingsSlot: View {
    @Environment(MCPModel.self) private var mcp: MCPModel?

    public init() {}

    public var body: some View {
        if let mcp { MCPSettingsSection().environment(mcp) }
    }
}

struct MCPImportPresenter: ViewModifier {
    @Environment(MCPModel.self) private var mcp: MCPModel?

    func body(content: Content) -> some View {
        content.sheet(
            item: Binding(get: { mcp?.pending }, set: { _ in })
        ) { request in
            ExternalImportScreen(preview: request.preview, source: request.source) { imported in
                mcp?.finish(request.id, imported: imported)
            }
        }
    }
}
