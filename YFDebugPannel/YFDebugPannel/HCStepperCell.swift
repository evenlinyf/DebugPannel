import UIKit

final class HCStepperCell: UITableViewCell {
    var valueChanged: ((Int) -> Void)?

    private let stepper = UIStepper()
    private let valueLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        stepper.addTarget(self, action: #selector(stepperChanged(_:)), for: .valueChanged)
        valueLabel.frame = CGRect(x: 0, y: 0, width: 40, height: 24)
        valueLabel.textAlignment = .right
        let stack = UIStackView(arrangedSubviews: [valueLabel, stepper])
        stack.axis = .horizontal
        stack.spacing = 8
        accessoryView = stack
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configure(with item: HCCellItem, minimum: Int, maximum: Int) {
        textLabel?.text = item.title
        detailTextLabel?.text = item.desc
        stepper.minimumValue = Double(minimum)
        stepper.maximumValue = Double(maximum)
        stepper.isEnabled = item.enabled
        let value = intValue(item.value)
        stepper.value = Double(value)
        valueLabel.text = String(value)
    }

    @objc private func stepperChanged(_ sender: UIStepper) {
        let value = Int(sender.value)
        valueLabel.text = String(value)
        valueChanged?(value)
    }
}
