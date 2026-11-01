//
//  DeviceStatusAPIManager.swift
//  FindMyCat
//

import Alamofire
import Foundation
import os.log

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
        return "https://\(host)/api"
    }

    private init() {}

    /// Asks the server to fetch the SIM status from Hologram; it lands in /state as "sim".
    func refreshSim(deviceId: Int, completion: @escaping () -> Void) {
        let url = "\(baseUrl)/devices/\(deviceId)/sim"
        logger.info("SIM refresh start: \(url, privacy: .public)")
        // Never from cache: each call must reach the server so it asks Hologram again.
        session.request(url, requestModifier: { $0.cachePolicy = .reloadIgnoringLocalCacheData })
            .validate()
            .response { [logger] response in
                let status = response.response?.statusCode ?? -1
                if let error = response.error {
                    logger.error("SIM refresh failed (\(status)): \(error.localizedDescription, privacy: .public)")
                } else {
                    logger.info("SIM refresh ok (\(status))")
                }
                completion()
            }
    }

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
