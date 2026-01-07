//
//  ViewController.swift
//  YFDebugPannel
//
//  Created by linyunfang on 2026/1/7.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let info = DebugPanelInfo.current()
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = info.displayText
        label.textAlignment = .center
        label.textColor = .secondaryLabel

        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("打开调试面板", for: .normal)
        button.addTarget(self, action: #selector(openDebugPanel), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [label, button])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func openDebugPanel() {
        let controller = HCEnvPanelViewController()
        let navigationController = UINavigationController(rootViewController: controller)
        present(navigationController, animated: true)
    }
}
