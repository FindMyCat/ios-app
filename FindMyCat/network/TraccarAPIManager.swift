import Alamofire
import Foundation

class TraccarAPIManager {
    static let shared = TraccarAPIManager()

    let session: Session
    
    // TODO: move to Info.plist
    let host = "ec2-18-191-185-127.us-east-2.compute.amazonaws.com:8082"

    private init() {
        CookieHandler.shared.restoreCookies()
        self.session = Session()
    }
    

    func fetchDevices(completion: @escaping (Result<[Device], Error>) -> Void) {
        let apiUrl = "http://\(host)/api/devices"
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
        let apiUrl = "http://\(host)/api/positions"
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
        let url = "http://\(host)/api/session"
        let method = HTTPMethod.get
        
        session
            .request(url, method: method)
            .validate(statusCode: 200..<300)
            .response { response in
                switch response.result {
                case .success(let value):
                    completion(.success(value))
                case .failure(_):
                    completion(.failure(GetSessionError.SessionNotFound))
                }
        }
    }
    
    func createSession(username: String, password: String, completion: @escaping (Result<Data?, Error>) -> Void) {
        // TODO: Use HTTPS when in production.
        let url = "http://\(host)/api/session"

        let headers: HTTPHeaders = [
            .accept("application/json"),
            .contentType("application/x-www-form-urlencoded"),
        ]

        struct Login: Encodable {
            let email: String
            let password: String
        }

        let login = Login(email: username , password: password)

        // create a session
        session
            .request(url, method: .post, parameters: login, headers: headers)
            .validate(statusCode: 200..<300)
            .response { response in
                CookieHandler.shared.backupCookies(forURL: url)
                debugPrint(response)
                switch response.result {
                case .success(let value):
                    // Session created successfully
                    print("Session created")
                    completion(.success(value))

                default:
                    let error = NSError(domain: "com.ChitlangeSahas.FindMyCat", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error creating session"])
                    print("Error Creating session: \(error)")
                    completion(.failure(error))
                }
        }
 
    }
}
