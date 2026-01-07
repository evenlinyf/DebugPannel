import UIKit

final class HCSwitchCell: UITableViewCell {
    var valueChanged: ((Bool) -> Void)?

    private let toggle = UISwitch()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        toggle.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        accessoryView = toggle
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configure(with item: HCCellItem) {
        textLabel?.text = item.title
        toggle.isOn = boolValue(item.value)
        toggle.isEnabled = item.enabled
    }

    @objc private func switchChanged(_ sender: UISwitch) {
        valueChanged?(sender.isOn)
    }
}
