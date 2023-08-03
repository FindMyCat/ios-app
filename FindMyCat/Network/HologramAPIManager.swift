//
//  HologramAPIManager.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 8/3/23.
//

import Alamofire
import Foundation
import os.log

class HologramAPIManager {
    let logger = Logger(subsystem: "Network", category: String(describing: HologramAPIManager.self))
    static let shared = HologramAPIManager()

    let session: Session

    let host = "dashboard.hologram.io"
    private var apiKey: String {
        get {

          guard let filePath = Bundle.main.path(forResource: "Info", ofType: "plist") else {
            fatalError("Couldn't find file 'Info.plist'.")
          }

          let plist = NSDictionary(contentsOfFile: filePath)
          guard let value = plist?.object(forKey: "HologramAPIKey") as? String else {
            fatalError("Couldn't find key 'HologramAPIKey' in 'Info.plist'.")
          }
          return value
        }
      }

    var orgId: Int {
        get {

          guard let filePath = Bundle.main.path(forResource: "Info", ofType: "plist") else {
            fatalError("Couldn't find file 'Info.plist'.")
          }

          let plist = NSDictionary(contentsOfFile: filePath)
          guard let value = plist?.object(forKey: "HologramOrgId") as? Int else {
            fatalError("Couldn't find key 'HologramOrgId' in 'Info.plist'.")
          }
          return value
        }
    }
    private init() {
        CookieHandlerUtil.shared.restoreCookies()
        self.session = Session()
    }

    func fetchDevice(name: String, orgId: Int?, completion: @escaping (Result<HologramDevice, Error>) -> Void) {
        let parameters = ["name": name, "orgid": orgId] as [String: Any]
        let user = "apikey" // Hologram rest API requires username as "apikey"
        let password = apiKey
        let credentialData = "\(user):\(password)".data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString(options: [])
        let headers = ["Authorization": "Basic \(base64Credentials)"] as HTTPHeaders

        let apiUrl = "https://\(host)/api/1/devices/"
        session.request(apiUrl, parameters: parameters, headers: headers)
            .responseDecodable(of: HologramDevicesResponse.self) { response in
                debugPrint(response)
                switch response.result {
                case .success(let devicesResponse):
                    // return the first match
                    completion(.success(devicesResponse.data![0]))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

    func sendCloudMessageToDevice(
        deviceId: Int, message: String,
        completion: @escaping (Result<Bool, Error>) -> Void) {
        let body = ["deviceids": [deviceId], "data": message, "port": "12345", "protocol": "UDP"] as [String: Any]
        let user = "apikey" // Hologram rest API requires username as "apikey"
        let password = apiKey
        let credentialData = "\(user):\(password)".data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString(options: [])
        let headers = ["Authorization": "Basic \(base64Credentials)"] as HTTPHeaders

        let apiUrl = "https://\(host)/api/1/devices/messages"
        session.request(apiUrl, method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers)
            .response { response in
                debugPrint(response)
                switch response.result {
                case .success(let devicesResponse):
                    completion(.success(true))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
