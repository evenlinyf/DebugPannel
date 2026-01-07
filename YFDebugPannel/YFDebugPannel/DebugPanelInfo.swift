//
//  DebugPanelInfo.swift
//  YFDebugPannel
//
//  Created by OpenAI on 2026/01/07.
//

import Foundation

struct DebugPanelInfo {
    let appName: String
    let buildNumber: String

    var displayText: String {
        "\(appName) (Build \(buildNumber))"
    }

    static func current() -> DebugPanelInfo {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "YFDebugPannel"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return DebugPanelInfo(appName: appName, buildNumber: buildNumber)
    }
}
