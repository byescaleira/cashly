public enum FeatureFlag: String, CaseIterable, Identifiable, Sendable {
    case mcpServer, mcpLocalNetwork, spreadsheetImport, guides, analytics

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .mcpServer: "Servidor MCP"
        case .mcpLocalNetwork: "MCP na rede local"
        case .spreadsheetImport: "Importar planilha"
        case .guides: "Guias"
        case .analytics: "Motor de análise"
        }
    }

    public var defaultValue: Bool {
        switch self {
        case .mcpServer, .mcpLocalNetwork, .spreadsheetImport, .guides, .analytics: true
        }
    }
}
