//
//  DeviceCommandsAPIManager.swift
//  FindMyCat
//

import Alamofire
import Foundation
import os.log

/// Sends commands to a collar through the device-commands service, which
/// holds the Hologram key and logs each command. It authorises with the
/// Traccar session cookie, which the shared cookie store already holds.
class DeviceCommandsAPIManager {
    let logger = Logger(subsystem: "Network", category: String(describing: DeviceCommandsAPIManager.self))
    static let shared = DeviceCommandsAPIManager()

    let session = Session()

    private var baseUrl: String {
        guard let filePath = Bundle.main.path(forResource: "Info", ofType: "plist") else {
            fatalError("Couldn't find file 'Info.plist'.")
        }

        let plist = NSDictionary(contentsOfFile: filePath)
        guard let host = plist?.object(forKey: "FindMyCat-Cloud-Hostname") as? String else {
            fatalError("Couldn't find key 'FindMyCat-Cloud-Hostname' in 'Info.plist'.")
        }
        return "https://\(host)/api/device-commands"
    }

    private init() {}

    /// `command` is one the collar's dispatcher knows: ping, lost, active, idle, spoof-ping.
    func send(_ command: String, toDeviceId deviceId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        session.request("\(baseUrl)/devices/\(deviceId)", method: .post,
                        parameters: ["command": command], encoder: JSONParameterEncoder.default)
            .validate()
            .response { response in
                switch response.result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
