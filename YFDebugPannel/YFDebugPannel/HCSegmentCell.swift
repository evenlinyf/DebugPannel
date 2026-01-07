import UIKit

final class HCSegmentCell: UITableViewCell {
    var valueChanged: ((Int) -> Void)?

    private let segmentedControl = UISegmentedControl(items: [])

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        accessoryView = segmentedControl
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configure(with item: HCCellItem) {
        textLabel?.text = item.title
        segmentedControl.isEnabled = item.enabled
        segmentedControl.removeAllSegments()
        for (index, title) in (item.options ?? []).enumerated() {
            segmentedControl.insertSegment(withTitle: title, at: index, animated: false)
        }
        let index = intValue(item.value)
        if index >= 0 && index < segmentedControl.numberOfSegments {
            segmentedControl.selectedSegmentIndex = index
        }
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        valueChanged?(sender.selectedSegmentIndex)
    }
}
