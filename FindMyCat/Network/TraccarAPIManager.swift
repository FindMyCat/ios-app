import Alamofire
import Foundation
import os.log

class TraccarAPIManager {
    let logger = Logger(subsystem: "Network", category: String(describing: TraccarAPIManager.self))
    static let shared = TraccarAPIManager()

    let session: Session

    private var host: String {
        get {
          guard let filePath = Bundle.main.path(forResource: "Info", ofType: "plist") else {
            fatalError("Couldn't find file 'Info.plist'.")
          }

          let plist = NSDictionary(contentsOfFile: filePath)
          guard let value = plist?.object(forKey: "FindMyCat-Cloud-Hostname") as? String else {
            fatalError("Couldn't find key 'FindMyCat-Cloud-Hostname' in 'Info.plist'.")
          }
          return value
        }
      }

    private init() {
        CookieHandlerUtil.shared.restoreCookies()
        self.session = Session()
    }

    func fetchDevices(completion: @escaping (Result<[Device], Error>) -> Void) {
        let apiUrl = "https://\(host)/api/devices"
        session.request(apiUrl).responseDecodable(of: [Device].self) { response in
            switch response.result {
            case .success(let devices):
                completion(.success(devices))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchPositions(completion: @escaping (Result<[Position], Error>) -> Void) {
        let apiUrl = "https://\(host)/api/positions"
        session.request(apiUrl).responseDecodable(of: [Position].self) { response in
            switch response.result {
            case .success(let positions):
                completion(.success(positions))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    enum GetSessionError: Error {
        case SessionNotFound
        case UnknownError
    }

    func getSession(completion: @escaping (Result<Data?, Error>) -> Void) {
        let url = "https://\(host)/api/session"
        let method = HTTPMethod.get

        session
            .request(url, method: method)
            .validate(statusCode: 200..<300)
            .response { response in
                switch response.result {
                case .success(let value):
                    completion(.success(value))
                case .failure:
                    completion(.failure(GetSessionError.SessionNotFound))
                }
        }
    }

    func createDevice(name: String, uniqueId: String, emoji: String, completion: @escaping (Result<Data?, Error>) -> Void) {
        let url = "https://\(host)/api/devices"

        let parameters = ["name": name, "uniqueId": uniqueId, "attributes": ["emoji": emoji]] as [String: Any]

        // create a device
        session
            .request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate(statusCode: 200..<300)
            .response { response in
                CookieHandlerUtil.shared.backupCookies(forURL: url)
                debugPrint(response)
                switch response.result {
                case .success(let value):
                    // Session created successfully
                    completion(.success(value))

                default:
                    let error = NSError(domain: "com.ChitlangeSahas.FindMyCat", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error Creating Device"])
                    self.logger.error("Error Creating Device: \(error)")
                    completion(.failure(error))
                }
        }

    }

    func updateDevice(name: String, id: Int, uniqueId: String, emoji: String, completion: @escaping (Result<Data?, Error>) -> Void) {
        let url = "https://\(host)/api/devices/\(id)"

        let parameters = ["name": name, "id": id, "uniqueId": uniqueId, "attributes": ["emoji": emoji]] as [String: Any]

        // create a device
        session
            .request(url, method: .put, parameters: parameters, encoding: JSONEncoding.default)
            .validate(statusCode: 200..<300)
            .response { response in
                CookieHandlerUtil.shared.backupCookies(forURL: url)
                switch response.result {
                case .success(let value):
                    // Session created successfully
                    completion(.success(value))
                default:
                    let error = NSError(domain: "com.ChitlangeSahas.FindMyCat", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error Creating Device"])
                    self.logger.error("Error Creating Device: \(error)")
                    completion(.failure(error))
                }
        }

    }

    func deleteDevice(id: Int, completion: @escaping (Result<Data?, Error>) -> Void) {
        let url = "https://\(host)/api/devices/\(id)"

        let method = HTTPMethod.delete

        // delete a device
        session
            .request(url, method: method)
            .validate(statusCode: 200..<300)
            .response { response in
                CookieHandlerUtil.shared.backupCookies(forURL: url)
                debugPrint(response)
                switch response.result {
                case .success(let value):
                    // Session created successfully
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                           SharedData.shared.updateDataFromApi()
                    }

                    completion(.success(value))

                default:
                    let error = NSError(domain: "com.ChitlangeSahas.FindMyCat", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error Deleting Device"])
                    self.logger.error("Error Deleting Device: \(error)")
                    completion(.failure(error))
                }
        }

    }

    func createSession(username: String, password: String, completion: @escaping (Result<Data?, Error>) -> Void) {
        let url = "https://\(host)/api/session"

        let headers: HTTPHeaders = [
            .accept("application/json"),
            .contentType("application/x-www-form-urlencoded")
        ]

        struct Login: Encodable {
            let email: String
            let password: String
        }

        let login = Login(email: username, password: password)

        // create a session
        session
            .request(url, method: .post, parameters: login, headers: headers)
            .validate(statusCode: 200..<300)
            .response { response in
                CookieHandlerUtil.shared.backupCookies(forURL: url)
                debugPrint(response)
                switch response.result {
                case .success(let value):
                    // Session created successfully
                    completion(.success(value))

                default:
                    let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error creating session"])
                    self.logger.error("Error Creating Session: \(error)")
                    completion(.failure(error))
                }
        }

    }
}
