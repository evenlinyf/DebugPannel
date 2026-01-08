import Foundation

let HCEnvItemIdEnvType = "env.type"
let HCEnvItemIdCluster = "env.cluster"
let HCEnvItemIdSaas = "env.saas"
let HCEnvItemIdIsolation = "env.isolation"
let HCEnvItemIdVersion = "env.version"
let HCEnvItemIdResult = "env.result"

private let envItemStoreIsolation = "HCEnvKit.isolation"
private let envItemStoreVersion = "HCEnvKit.version"
private let envItemStoreCluster = "HCEnvKit.cluster"
private let envItemStoreSaas = "HCEnvKit.saas"
private let envClusterMin = 1
private let envClusterMax = 5
private let envSaasPrefix = "hpc-uat-"

private func configFromItems(_ itemsById: [String: HCCellItem]) -> HCEnvConfig {
    let config = HCEnvConfig()
    let envItem = itemsById[HCEnvItemIdEnvType]
    let clusterItem = itemsById[HCEnvItemIdCluster]
    let isolationItem = itemsById[HCEnvItemIdIsolation]
    let versionItem = itemsById[HCEnvItemIdVersion]
    config.envType = HCEnvType(rawValue: intValue(envItem?.value)) ?? .release
    config.clusterIndex = max(envClusterMin, intValue(clusterItem?.value))
    config.isolation = isolationItem?.value as? String ?? ""
    config.version = versionItem?.value as? String ?? "v1"
    return config
}

enum HCEnvBuilder {
    static func buildEnvSection() -> HCEnvSection {
        let config = HCEnvKit.currentConfig()

        let envType = HCCellItem.item(identifier: HCEnvItemIdEnvType, title: "环境类型", type: .segment)
        envType.options = ["线上", "uat", "dev"]
        envType.value = config.envType.rawValue

        let cluster = HCCellItem.item(identifier: HCEnvItemIdCluster, title: "环境编号", type: .stepper)
        cluster.storeKey = envItemStoreCluster
        cluster.defaultValue = 1
        let initialCluster = max(envClusterMin, config.clusterIndex)
        cluster.value = initialCluster
        cluster.detail = String(initialCluster)
        cluster.disabledHint = "仅 uat/dev 可用"
        cluster.dependsOn = [HCEnvItemIdEnvType]
        cluster.recomputeBlock = { item, itemsById in
            let envItem = itemsById[HCEnvItemIdEnvType]
            let envTypeValue = HCEnvType(rawValue: intValue(envItem?.value)) ?? .release
            item.enabled = envTypeValue != .release
            var current = max(envClusterMin, intValue(item.value))
            current = min(envClusterMax, current)
            item.value = current
            item.detail = String(current)
        }

        let saas = HCCellItem.item(identifier: HCEnvItemIdSaas, title: "Saas 环境", type: .string)
        saas.storeKey = envItemStoreSaas
        saas.value = "\(envSaasPrefix)\(initialCluster)"
        saas.detail = saas.value as? String
        saas.disabledHint = "仅 uat/dev 可用"
        saas.dependsOn = [HCEnvItemIdEnvType, HCEnvItemIdCluster]
        saas.recomputeBlock = { item, itemsById in
            let envItem = itemsById[HCEnvItemIdEnvType]
            let envTypeValue = HCEnvType(rawValue: intValue(envItem?.value)) ?? .release
            item.enabled = envTypeValue != .release
            let clusterValue = max(envClusterMin, intValue(itemsById[HCEnvItemIdCluster]?.value))
            let autoValue = "\(envSaasPrefix)\(clusterValue)"
            if let current = item.value as? String {
                let matchesAuto = current.hasPrefix(envSaasPrefix) && Int(current.replacingOccurrences(of: envSaasPrefix, with: "")) != nil
                if matchesAuto {
                    item.value = autoValue
                }
            } else {
                item.value = autoValue
            }
            item.detail = item.value as? String
        }

        let isolation = HCCellItem.item(identifier: HCEnvItemIdIsolation, title: "隔离参数", type: .string)
        isolation.storeKey = envItemStoreIsolation
        isolation.defaultValue = ""
        isolation.value = config.isolation
        isolation.detail = config.isolation
        isolation.disabledHint = "仅 uat/dev 可用"
        isolation.dependsOn = [HCEnvItemIdEnvType]
        isolation.recomputeBlock = { item, itemsById in
            let envItem = itemsById[HCEnvItemIdEnvType]
            let envTypeValue = HCEnvType(rawValue: intValue(envItem?.value)) ?? .release
            item.enabled = envTypeValue != .release
            item.detail = item.value as? String
        }

        let version = HCCellItem.item(identifier: HCEnvItemIdVersion, title: "版本号", type: .string)
        version.storeKey = envItemStoreVersion
        version.defaultValue = "v1"
        version.value = config.version
        version.detail = config.version
        version.disabledHint = "仅 uat/dev 可用"
        version.dependsOn = [HCEnvItemIdEnvType]
        version.validator = { input in
            let regex = try? NSRegularExpression(pattern: "^v\\d+$", options: [])
            let matches = regex?.numberOfMatches(in: input, options: [], range: NSRange(location: 0, length: input.count)) ?? 0
            return matches == 0 ? "版本号格式必须为 v+数字" : nil
        }
        version.recomputeBlock = { item, itemsById in
            let envItem = itemsById[HCEnvItemIdEnvType]
            let envTypeValue = HCEnvType(rawValue: intValue(envItem?.value)) ?? .release
            item.enabled = envTypeValue != .release
            item.detail = item.value as? String
        }

        let result = HCCellItem.item(identifier: HCEnvItemIdResult, title: "生效结果", type: .info)
        result.desc = ""
        result.detail = ""
        result.dependsOn = [HCEnvItemIdEnvType, HCEnvItemIdCluster, HCEnvItemIdVersion, HCEnvItemIdIsolation]
        result.recomputeBlock = { item, itemsById in
            let config = configFromItems(itemsById)
            let build = HCEnvKit.buildResult(config)
            item.detail = build.displayName
            item.desc = build.baseURL
        }

        let items = [envType, cluster, saas, isolation, version, result]
        let section = HCEnvSection.section(title: "环境配置", items: items)

        let itemsById = indexItemsById(from: section)
        for item in items {
            item.recomputeBlock?(item, itemsById)
        }

        return section
    }

    static func indexItemsById(from section: HCEnvSection) -> [String: HCCellItem] {
        var itemsById: [String: HCCellItem] = [:]
        for item in section.items where !item.identifier.isEmpty {
            itemsById[item.identifier] = item
        }
        return itemsById
    }
}
