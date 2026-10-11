//
//  DeviceStatusViewController.swift
//  FindMyCat
//

import UIKit

/// Lists every field of a device's DeviceState, one section per event kind.
/// Reflection keeps it in step with the model as kinds and fields are added.
class DeviceStatusViewController: UITableViewController {
    private let deviceId: Int
    private var sections: [(kind: String, fields: [(key: String, value: String)])] = []
    private var message: String? = "Loading…"

    init(deviceId: Int, deviceName: String) {
        self.deviceId = deviceId
        super.init(style: .insetGrouped)
        title = "\(deviceName) status"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .done, primaryAction: UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        })
        refreshControl = UIRefreshControl()
        refreshControl?.addAction(UIAction { [weak self] _ in self?.load() }, for: .valueChanged)
        load()
    }

    private func load() {
        DeviceStatusAPIManager.shared.fetchDeviceState(deviceId: deviceId) { [weak self] result in
            guard let self else { return }
            self.refreshControl?.endRefreshing()

            switch result {
            case .success(let state):
                self.sections = Self.sections(of: state)
                self.message = self.sections.isEmpty ? "No status reported yet" : nil
            case .failure(let error):
                self.sections = []
                self.message = error.localizedDescription
            }
            self.tableView.reloadData()
        }
    }

    private static func sections(of state: DeviceState) -> [(kind: String, fields: [(key: String, value: String)])] {
        Mirror(reflecting: state).children.compactMap { child in
            guard let kind = child.label, let event = unwrap(child.value) else { return nil }
            let fields = Mirror(reflecting: event).children.compactMap { field -> (key: String, value: String)? in
                guard let key = field.label else { return nil }
                return (key, unwrap(field.value).map { "\($0)" } ?? "—")
            }
            return (kind, fields)
        }
    }

    /// The wrapped value of an Optional, nil for .none; other values as is.
    private static func unwrap(_ value: Any) -> Any? {
        let mirror = Mirror(reflecting: value)
        guard mirror.displayStyle == .optional else { return value }
        return mirror.children.first.map { unwrap($0.value) } ?? nil
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        max(sections.count, 1)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections.isEmpty ? 1 : sections[section].fields.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections.isEmpty ? nil : sections[section].kind
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.selectionStyle = .none
        var content = UIListContentConfiguration.valueCell()

        if sections.isEmpty {
            content.text = message
        } else {
            let field = sections[indexPath.section].fields[indexPath.row]
            content.text = field.key
            content.secondaryText = field.value
            content.secondaryTextProperties.numberOfLines = 0
        }

        cell.contentConfiguration = content
        return cell
    }
}
