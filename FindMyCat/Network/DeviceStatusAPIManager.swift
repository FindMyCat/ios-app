//
//  DeviceStatusAPIManager.swift
//  FindMyCat
//

import Alamofire
import Foundation
import os.log

/// Talks to the device-status service on the cloud host. It authorises with
/// the Traccar session cookie, which the shared cookie store already holds.
class DeviceStatusAPIManager {
    let logger = Logger(subsystem: "Network", category: String(describing: DeviceStatusAPIManager.self))
    static let shared = DeviceStatusAPIManager()

    let session = Session()

    private var baseUrl: String {
        guard let filePath = Bundle.main.path(forResource: "Info", ofType: "plist") else {
            fatalError("Couldn't find file 'Info.plist'.")
        }

        let plist = NSDictionary(contentsOfFile: filePath)
        guard let host = plist?.object(forKey: "FindMyCat-Cloud-Hostname") as? String else {
            fatalError("Couldn't find key 'FindMyCat-Cloud-Hostname' in 'Info.plist'.")
        }
        return "https://\(host)/api/device-status"
    }

    private init() {}

    /// Latest event of each kind for one device.
    func fetchDeviceState(deviceId: Int, completion: @escaping (Result<DeviceState, Error>) -> Void) {
        session.request("\(baseUrl)/devices/\(deviceId)/state")
            .validate()
            .responseDecodable(of: DeviceState.self, decoder: DeviceState.decoder) { response in
                switch response.result {
                case .success(let state):
                    completion(.success(state))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
