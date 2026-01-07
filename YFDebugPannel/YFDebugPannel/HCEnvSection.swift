import Foundation

final class HCEnvSection {
    var title: String
    var items: [HCCellItem]

    init(title: String, items: [HCCellItem]) {
        self.title = title
        self.items = items
    }

    static func section(title: String, items: [HCCellItem]) -> HCEnvSection {
        HCEnvSection(title: title, items: items)
    }
}
