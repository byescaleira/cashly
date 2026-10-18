import CloudKit

enum SharedZone {
    static let prefix = "profile."

    static func name(for profileID: String) -> String { prefix + profileID }

    static func profileID(of zoneID: CKRecordZone.ID) -> String? {
        guard zoneID.zoneName.hasPrefix(prefix) else { return nil }
        let id = String(zoneID.zoneName.dropFirst(prefix.count))
        return id.isEmpty ? nil : id
    }

    static func id(for profileID: String, owner: String = CKCurrentUserDefaultName)
        -> CKRecordZone.ID
    {
        CKRecordZone.ID(zoneName: name(for: profileID), ownerName: owner)
    }

    static func shareID(for zoneID: CKRecordZone.ID) -> CKRecord.ID {
        CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: zoneID)
    }

    static func archive(_ record: CKRecord) -> Data {
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        record.encodeSystemFields(with: coder)
        coder.finishEncoding()
        return coder.encodedData
    }

    static func unarchive(_ data: Data) -> CKRecord? {
        guard let coder = try? NSKeyedUnarchiver(forReadingFrom: data) else { return nil }
        coder.requiresSecureCoding = true
        defer { coder.finishDecoding() }
        return CKRecord(coder: coder)
    }
}
