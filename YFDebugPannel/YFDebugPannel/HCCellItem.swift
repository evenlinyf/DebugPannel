import Foundation

enum HCCellItemType: Int {
    case toggle
    case string
    case stepper
    case action
    case segment
    case picker
    case info
}

typealias HCCellItemRecomputeBlock = (_ item: HCCellItem, _ itemsById: [String: HCCellItem]) -> Void

typealias HCCellItemValidator = (_ input: String) -> String?

typealias HCCellItemValueTransformer = (_ item: HCCellItem) -> Void

final class HCCellItem {
    let identifier: String
    var title: String
    var desc: String?
    var detail: String?
    var enabled: Bool = true
    var disabledHint: String?

    var type: HCCellItemType
    var value: Any?

    var storeKey: String?
    var defaultValue: Any?

    var options: [String]?
    var dependsOn: [String]?
    var recomputeBlock: HCCellItemRecomputeBlock?

    var validator: HCCellItemValidator?
    var valueTransformer: HCCellItemValueTransformer?

    init(identifier: String, title: String, type: HCCellItemType) {
        self.identifier = identifier
        self.title = title
        self.type = type
    }

    static func item(identifier: String, title: String, type: HCCellItemType) -> HCCellItem {
        let item = HCCellItem(identifier: identifier, title: title, type: type)
        item.enabled = true
        return item
    }
}
