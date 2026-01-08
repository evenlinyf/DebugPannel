import UIKit

final class HCEnvPanelViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let viewModel = HCEnvPanelViewModel()

    private let segmentCellId = "HCSegmentCell"
    private let switchCellId = "HCSwitchCell"
    private let stepperCellId = "HCStepperCell"
    private let valueCellId = "HCValueCell"
    private let infoCellId = "HCInfoCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "调试面板"
        view.backgroundColor = .systemBackground

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(HCSegmentCell.self, forCellReuseIdentifier: segmentCellId)
        tableView.register(HCSwitchCell.self, forCellReuseIdentifier: switchCellId)
        tableView.register(HCStepperCell.self, forCellReuseIdentifier: stepperCellId)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        if presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "关闭", style: .plain, target: self, action: #selector(closeTapped))
        }
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    private func applyValue(_ value: Any?, for item: HCCellItem) {
        let paths = viewModel.updateItem(item, value: value)
        guard !paths.isEmpty else { return }
        tableView.reloadRows(at: paths, with: .automatic)
    }

    private func presentStringInput(for item: HCCellItem) {
        let alert = UIAlertController(title: item.title, message: item.desc, preferredStyle: .alert)
        alert.addTextField { textField in
            if let value = item.value {
                textField.text = String(describing: value)
            }
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            let text = alert.textFields?.first?.text ?? ""
            if let validator = item.validator, let errorMessage = validator(text) {
                self?.presentRequest(HCPresentationRequest.toast(message: errorMessage))
                return
            }
            self?.applyValue(text, for: item)
        })
        present(alert, animated: true)
    }

    private func presentPicker(for item: HCCellItem) {
        let sheet = UIAlertController(title: item.title, message: item.desc, preferredStyle: .actionSheet)
        for option in item.options ?? [] {
            sheet.addAction(UIAlertAction(title: option, style: .default) { [weak self] _ in
                self?.applyValue(option, for: item)
            })
        }
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }
        present(sheet, animated: true)
    }

    private func presentRequest(_ request: HCPresentationRequest) {
        guard request.type == .toast else { return }
        let alert = UIAlertController(title: nil, message: request.title, preferredStyle: .alert)
        present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                alert.dismiss(animated: true)
            }
        }
    }
}

extension HCEnvPanelViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.sections[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        viewModel.sections[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = viewModel.item(at: indexPath)
        switch item.type {
        case .segment:
            let cell = tableView.dequeueReusableCell(withIdentifier: segmentCellId, for: indexPath) as! HCSegmentCell
            cell.valueChanged = { [weak self] selectedIndex in
                self?.applyValue(selectedIndex, for: item)
            }
            cell.configure(with: item)
            return cell
        case .toggle:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! HCSwitchCell
            cell.valueChanged = { [weak self] isOn in
                self?.applyValue(isOn, for: item)
            }
            cell.configure(with: item)
            return cell
        case .stepper:
            let cell = tableView.dequeueReusableCell(withIdentifier: stepperCellId, for: indexPath) as! HCStepperCell
            cell.valueChanged = { [weak self] value in
                self?.applyValue(value, for: item)
            }
            cell.configure(with: item, minimum: 1, maximum: 5)
            return cell
        case .info:
            let cell = tableView.dequeueReusableCell(withIdentifier: infoCellId) ?? UITableViewCell(style: .subtitle, reuseIdentifier: infoCellId)
            cell.selectionStyle = .none
            cell.textLabel?.text = item.title
            cell.textLabel?.textColor = .label
            cell.detailTextLabel?.textColor = .secondaryLabel
            cell.isUserInteractionEnabled = false
            cell.accessoryType = .none
            if let desc = item.desc, !desc.isEmpty {
                let detail = item.detail ?? ""
                cell.detailTextLabel?.text = "\(detail)\n\(desc)"
                cell.detailTextLabel?.numberOfLines = 0
            } else {
                cell.detailTextLabel?.text = item.detail
                cell.detailTextLabel?.numberOfLines = 1
            }
            return cell
        case .string, .picker, .action:
            let cell = tableView.dequeueReusableCell(withIdentifier: valueCellId) ?? UITableViewCell(style: .value1, reuseIdentifier: valueCellId)
            cell.textLabel?.text = item.title
            cell.detailTextLabel?.text = item.detail
            cell.textLabel?.textColor = item.enabled ? .label : .secondaryLabel
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            return cell
        }
    }
}

extension HCEnvPanelViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = viewModel.item(at: indexPath)
        if !item.enabled {
            presentRequest(viewModel.presentationForDisabledItem(item))
            return
        }
        switch item.type {
        case .string:
            presentStringInput(for: item)
        case .picker:
            presentPicker(for: item)
        case .action:
            applyValue(item.value, for: item)
        default:
            break
        }
    }
}
