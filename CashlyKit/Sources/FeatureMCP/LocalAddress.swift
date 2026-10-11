import Foundation

enum LocalAddress {
    static var current: String? {
        var pointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&pointer) == 0, let first = pointer else { return nil }
        defer { freeifaddrs(pointer) }
        var candidates: [(name: String, address: String)] = []
        for item in sequence(first: first, next: { $0.pointee.ifa_next }) {
            guard let address = item.pointee.ifa_addr, address.pointee.sa_family == UInt8(AF_INET)
            else {
                continue
            }
            let name = String(cString: item.pointee.ifa_name)
            guard name.hasPrefix("en") || name.hasPrefix("bridge") else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            guard
                getnameinfo(
                    address, socklen_t(address.pointee.sa_len), &host, socklen_t(host.count), nil,
                    0,
                    NI_NUMERICHOST) == 0
            else { continue }
            candidates.append(
                (name, String(decoding: host.prefix { $0 != 0 }.map(UInt8.init), as: UTF8.self)))
        }
        return candidates.sorted { $0.name < $1.name }.first?.address
    }
}
