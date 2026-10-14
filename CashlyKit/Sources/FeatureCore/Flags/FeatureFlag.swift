import CashlyDomain

public enum FeatureFlag: String, CaseIterable, Identifiable, Sendable {
    case mcpServer, mcpLocalNetwork, spreadsheetImport, guides, analytics, journey, pro,
        intelligence

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .mcpServer: String(appLocalized: "MCP server")
        case .mcpLocalNetwork: String(appLocalized: "MCP on the local network")
        case .spreadsheetImport: String(appLocalized: "Spreadsheet import")
        case .guides: String(appLocalized: "Guides")
        case .analytics: String(appLocalized: "Analytics engine")
        case .journey: String(appLocalized: "Journey")
        case .pro: String(appLocalized: "Cashly Pro paywall")
        case .intelligence: String(appLocalized: "On-device intelligence")
        }
    }

    public var defaultValue: Bool {
        switch self {
        case .mcpServer, .mcpLocalNetwork, .spreadsheetImport, .guides, .analytics, .journey, .pro:
            true
        case .intelligence: false
        }
    }
}
