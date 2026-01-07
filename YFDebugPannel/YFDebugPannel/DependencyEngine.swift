import Foundation

final class DependencyEngine {
    let itemsById: [String: HCCellItem]
    private let reverseDeps: [String: [String]]

    init(items: [HCCellItem]) {
        var itemsById: [String: HCCellItem] = [:]
        var reverseDeps: [String: [String]] = [:]
        for item in items where !item.identifier.isEmpty {
            itemsById[item.identifier] = item
        }
        for item in items {
            for depId in item.dependsOn ?? [] {
                reverseDeps[depId, default: []].append(item.identifier)
            }
        }
        self.itemsById = itemsById
        self.reverseDeps = reverseDeps
    }

    func propagateFromItemId(_ itemId: String) -> Set<String> {
        var changed = Set<String>()
        var queue = reverseDeps[itemId] ?? []

        while !queue.isEmpty {
            let currentId = queue.removeFirst()
            guard let item = itemsById[currentId], let recompute = item.recomputeBlock else {
                continue
            }
            let oldEnabled = item.enabled
            let oldDetail = item.detail
            let oldValue = item.value
            recompute(item, itemsById)
            let valueChanged = oldEnabled != item.enabled
                || !valueEqual(oldDetail, item.detail)
                || !valueEqual(oldValue, item.value)
            if valueChanged {
                changed.insert(currentId)
                queue.append(contentsOf: reverseDeps[currentId] ?? [])
            }
        }

        return changed
    }
}

private func valueEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
    if lhs == nil && rhs == nil {
        return true
    }
    if let lhs = lhs as? NSObject, let rhs = rhs as? NSObject {
        return lhs == rhs
    }
    return false
}
