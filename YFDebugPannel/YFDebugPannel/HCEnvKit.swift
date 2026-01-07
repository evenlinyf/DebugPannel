import Foundation

enum HCEnvType: Int {
    case release
    case uat
    case dev
}

let HCEnvKitConfigDidChangeNotification = Notification.Name("HCEnvKitConfigDidChangeNotification")

final class HCEnvConfig {
    var envType: HCEnvType = .release
    var clusterIndex: Int = 1
    var isolation: String = ""
    var version: String = "v1"
}

final class HCEnvBuildResult {
    var baseURL: String = ""
    var displayName: String = ""
    var isolation: String = ""
}

enum HCEnvKit {
    private static let defaultsKey = "HCEnvKit.config"
    private static let releaseBaseURL = "https://release.example.com"
    private static let uatTemplate = "https://uat-%ld-%@.example.com"
    private static let devTemplate = "https://dev-%ld-%@.example.com"

    static func currentConfig() -> HCEnvConfig {
        let stored = UserDefaults.standard.dictionary(forKey: defaultsKey)
        let config = HCEnvConfig()
        if let stored {
            if let envType = stored["envType"] as? Int {
                config.envType = HCEnvType(rawValue: envType) ?? .release
            }
            if let clusterIndex = stored["clusterIndex"] as? Int {
                config.clusterIndex = clusterIndex
            }
            config.isolation = stored["isolation"] as? String ?? ""
            config.version = stored["version"] as? String ?? "v1"
        } else {
            config.envType = .release
            config.clusterIndex = 1
            config.isolation = ""
            config.version = "v1"
        }
        return config
    }

    static func saveConfig(_ config: HCEnvConfig) {
        let payload: [String: Any] = [
            "envType": config.envType.rawValue,
            "clusterIndex": config.clusterIndex,
            "isolation": config.isolation,
            "version": config.version
        ]
        UserDefaults.standard.set(payload, forKey: defaultsKey)
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: HCEnvKitConfigDidChangeNotification, object: nil)
    }

    static func buildResult(_ config: HCEnvConfig) -> HCEnvBuildResult {
        let result = HCEnvBuildResult()
        result.isolation = config.isolation
        switch config.envType {
        case .release:
            result.displayName = "线上"
            result.baseURL = releaseBaseURL
            return result
        case .uat, .dev:
            break
        }
        let version = config.version.isEmpty ? "v1" : config.version
        if config.envType == .uat {
            result.displayName = "uat-\(config.clusterIndex)"
            result.baseURL = String(format: uatTemplate, config.clusterIndex, version)
        } else {
            result.displayName = "dev-\(config.clusterIndex)"
            result.baseURL = String(format: devTemplate, config.clusterIndex, version)
        }
        return result
    }
}
