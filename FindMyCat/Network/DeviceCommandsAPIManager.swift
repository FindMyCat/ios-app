//
//  DeviceCommandsAPIManager.swift
//  FindMyCat
//

import Alamofire
import Foundation
import os.log

class DeviceCommandsAPIManager {
    let logger = Logger(subsystem: "Network", category: String(describing: DeviceCommandsAPIManager.self))
    static let shared = DeviceCommandsAPIManager()

    let session = Session()

    private var host: String {
        guard let filePath = Bundle.main.path(forResource: "Info", ofType: "plist") else {
            fatalError("Couldn't find file 'Info.plist'.")
        }

        let plist = NSDictionary(contentsOfFile: filePath)
        guard let host = plist?.object(forKey: "FindMyCat-Cloud-Hostname") as? String else {
            fatalError("Couldn't find key 'FindMyCat-Cloud-Hostname' in 'Info.plist'.")
        }
        return host
    }

    private var baseUrl: String {
        return "https://\(host)/api/device-commands"
    }

    private init() {}

    func send(_ command: String, toDeviceId deviceId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        session.request("https://\(host)/api/devices/\(deviceId)/command/\(command)", method: .post)
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

    /// Downloads a file uploaded with `make fw-upload`, e.g. indoor_update.zip.
    func downloadFirmware(_ file: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let destination: DownloadRequest.Destination = { _, _ in
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(file)
            return (url, [.removePreviousFile])
        }
        session.download("\(baseUrl)/firmware/\(file)", to: destination)
            .validate()
            .response { response in
                switch response.result {
                case .success(let url):
                    completion(url.map { .success($0) } ?? .failure(AFError.responseValidationFailed(reason: .dataFileNil)))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
