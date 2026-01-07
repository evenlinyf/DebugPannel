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

        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
