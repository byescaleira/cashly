import CashlyDomain
import Foundation

public struct ExchangeCache: Sendable {
    public static var defaultDirectory: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appending(path: "ExchangeRates", directoryHint: .isDirectory)
    }

    struct CurrencyList: Codable {
        let codes: [String]
        let fetchedAt: Date
    }

    let directory: URL?

    func table(_ key: String) -> ExchangeTable? {
        read(ExchangeTable.self, name: key)
    }

    func save(_ table: ExchangeTable, key: String) {
        write(table, name: key)
    }

    func currencies() -> CurrencyList? {
        read(CurrencyList.self, name: "currencies")
    }

    func save(_ list: CurrencyList) {
        write(list, name: "currencies")
    }

    private func read<Value: Decodable>(_ type: Value.Type, name: String) -> Value? {
        guard let url = directory?.appending(path: "\(name).json"),
            let data = try? Data(contentsOf: url)
        else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func write<Value: Encodable>(_ value: Value, name: String) {
        guard let directory, let data = try? JSONEncoder().encode(value) else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: directory.appending(path: "\(name).json"), options: .atomic)
    }
}
