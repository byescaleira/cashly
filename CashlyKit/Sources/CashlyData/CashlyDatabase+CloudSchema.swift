#if DEBUG
    import CoreData
    import Foundation
    import SwiftData

    extension CashlyDatabase {
        public static func initializeCloudSchema() {
            let url = FileManager.default.temporaryDirectory
                .appending(path: "CloudSchema-\(UUID().uuidString).store")
            guard
                let model = NSManagedObjectModel.makeManagedObjectModel(
                    for: CashlySchemaV6.models)
            else {
                CashlyMetrics.logger.error("Cloud schema: model could not be built")
                return
            }
            let description = NSPersistentStoreDescription(url: url)
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: cloudContainer)
            description.shouldAddStoreAsynchronously = false
            let container = NSPersistentCloudKitContainer(
                name: "CloudSchema", managedObjectModel: model)
            container.persistentStoreDescriptions = [description]
            var loadError: (any Error)?
            container.loadPersistentStores { _, error in loadError = error }
            if let loadError {
                CashlyMetrics.failure("CloudSchemaLoad", error: loadError)
                return
            }
            do {
                try container.initializeCloudKitSchema()
                CashlyMetrics.logger.notice("Cloud schema: initialized")
            } catch {
                CashlyMetrics.failure("CloudSchemaInitialize", error: error)
            }
            for store in container.persistentStoreCoordinator.persistentStores {
                try? container.persistentStoreCoordinator.remove(store)
            }
            try? FileManager.default.removeItem(at: url)
        }
    }
#endif
