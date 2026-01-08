import Foundation
import UIKit

final class HCEnvPanelViewModel {
    private(set) var sections: [HCEnvSection]
    private var dependencyEngine: DependencyEngine
    private var indexMap: [String: IndexPath]

    init() {
        let envSection = HCEnvBuilder.buildEnvSection()
        self.sections = [envSection]
        self.dependencyEngine = DependencyEngine(items: envSection.items)
        self.indexMap = [:]
        loadPersistedValues()
        rebuildIndexMap()
        rebuildDependencyEngine()
        refreshAllItems()
    }

    func item(at indexPath: IndexPath) -> HCCellItem {
        sections[indexPath.section].items[indexPath.row]
    }

    func updateItem(_ item: HCCellItem, value: Any?) -> [IndexPath] {
        item.value = value
        if item.type == .string || item.type == .stepper {
            item.detail = value.map { String(describing: $0) }
        }
        item.valueTransformer?(item)

        var changed = Set<String>()
        if !item.identifier.isEmpty {
            changed.insert(item.identifier)
            let propagated = dependencyEngine.propagateFromItemId(item.identifier)
            changed.formUnion(propagated)
        }

        persistIfNeeded(for: item)
        persistEnvConfig()

        var paths: [IndexPath] = []
        for itemId in changed {
            if let indexPath = indexMap[itemId] {
                paths.append(indexPath)
            }
        }
        return paths
    }

    func presentationForDisabledItem(_ item: HCCellItem) -> HCPresentationRequest {
        if let hint = item.disabledHint, !hint.isEmpty {
            return HCPresentationRequest.toast(message: hint)
        }
        return HCPresentationRequest.toast(message: "当前不可用")
    }

    private func loadPersistedValues() {
        for section in sections {
            for item in section.items {
                guard let storeKey = item.storeKey, !storeKey.isEmpty else {
                    continue
                }
                if let stored = UserDefaults.standard.object(forKey: storeKey) {
                    item.value = stored
                } else if let defaultValue = item.defaultValue {
                    item.value = defaultValue
                }
                if item.type == .string || item.type == .stepper {
                    item.detail = item.value.map { String(describing: $0) }
                }
            }
        }
    }

    private func rebuildDependencyEngine() {
        let items = sections.flatMap { $0.items }
        dependencyEngine = DependencyEngine(items: items)
    }

    private func refreshAllItems() {
        let itemsById = dependencyEngine.itemsById
        for section in sections {
            for item in section.items {
                item.recomputeBlock?(item, itemsById)
            }
        }
    }

    private func rebuildIndexMap() {
        var map: [String: IndexPath] = [:]
        for (sectionIndex, section) in sections.enumerated() {
            for (rowIndex, item) in section.items.enumerated() {
                if !item.identifier.isEmpty {
                    map[item.identifier] = IndexPath(row: rowIndex, section: sectionIndex)
                }
            }
        }
        indexMap = map
    }

    private func persistIfNeeded(for item: HCCellItem) {
        guard let storeKey = item.storeKey, !storeKey.isEmpty else {
            return
        }
        if let value = item.value {
            UserDefaults.standard.set(value, forKey: storeKey)
        } else {
            UserDefaults.standard.removeObject(forKey: storeKey)
        }
        UserDefaults.standard.synchronize()
    }

    private func persistEnvConfig() {
        let itemsById = dependencyEngine.itemsById
        guard let envItem = itemsById[HCEnvItemIdEnvType],
              let clusterItem = itemsById[HCEnvItemIdCluster],
              let isolationItem = itemsById[HCEnvItemIdIsolation],
              let versionItem = itemsById[HCEnvItemIdVersion] else {
            return
        }

        let config = HCEnvConfig()
        config.envType = HCEnvType(rawValue: intValue(envItem.value)) ?? .release
        config.clusterIndex = intValue(clusterItem.value)
        config.isolation = isolationItem.value as? String ?? ""
        config.version = versionItem.value as? String ?? "v1"
        HCEnvKit.saveConfig(config)
    }
}
