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
                guard let key = field.label, key != "id" else { return nil }
                return (label(key), unwrap(field.value).map { format($0, key: key) } ?? "—")
            }
            return (kind.capitalized, fields)
        }
    }

    /// Field names end in their unit ("_s", "_ms", "_m"), so the unit decides the format.
    private static let units = ["_ms", "_s", "_m"]

    /// "edrx_s" -> "Edrx", "receivedAt" -> "Received at"
    private static func label(_ key: String) -> String {
        let name = units.first { key.hasSuffix($0) }.map { String(key.dropLast($0.count)) } ?? key
        let words = name.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .replacingOccurrences(of: "_", with: " ").lowercased()
        return words.prefix(1).uppercased() + words.dropFirst()
    }

    private static func format(_ value: Any, key: String) -> String {
        if let date = value as? Date {
            return date.formatted(date: .abbreviated, time: .standard) + " (" + date.formatted(.relative(presentation: .named)) + ")"
        }
        guard let number = (value as? NSNumber)?.doubleValue else { return "\(value)" }

        if key.hasSuffix("_ms") { return format(Date(timeIntervalSince1970: number / 1000), key: "") }
        if key.hasSuffix("_s") { return "\(number.formatted()) s" }
        if key.hasSuffix("_m") { return "\(number.formatted()) m" }
        // lte_lc_lte_mode
        if key == "mode" { return [0: "None", 7: "LTE-M", 9: "NB-IoT"][Int(number)] ?? "\(Int(number))" }
        return number.formatted()
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
