import UIKit

final class HCStepperCell: UITableViewCell {
    var valueChanged: ((Int) -> Void)?

    private let stepper = UIStepper()
    private let valueLabel = UILabel()
    private let stackView = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        stepper.addTarget(self, action: #selector(stepperChanged(_:)), for: .valueChanged)
        valueLabel.textAlignment = .right
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.addArrangedSubview(valueLabel)
        stackView.addArrangedSubview(stepper)
        valueLabel.widthAnchor.constraint(equalToConstant: 40).isActive = true
        accessoryView = stackView
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
