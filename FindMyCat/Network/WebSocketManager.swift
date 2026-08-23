//
//  WebSocketManager.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/25/23.
//

import Starscream
import Combine
import Foundation
import os.log

class WebSocketManager: WebSocketDelegate {

    let logger = Logger(subsystem: "Network", category: String(describing: WebSocketManager.self))

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

    private var socket: WebSocket?
    private var cancellables = Set<AnyCancellable>()

    private var isConnected: Bool = false
    private var shouldReconnect: Bool = true
    private var reconnectAttempt: Int = 0
    private let subject = PassthroughSubject<String, Never>()

    var dataPublisher: AnyPublisher<String, Never> {
        return subject.eraseToAnyPublisher()
    }

    func connect() {
        shouldReconnect = true

        let urlString = "wss://\(host)/api/socket"
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        CookieHandlerUtil.shared.restoreCookies()
        let cookies = HTTPCookieStorage.shared.cookies(for: URL(string: "https://\(host)")!) ?? []
        if !cookies.isEmpty {
            for (field, value) in HTTPCookie.requestHeaderFields(with: cookies) {
                request.setValue(value, forHTTPHeaderField: field)
            }
            logger.log("connecting to \(urlString) with cookies: \(cookies.map { $0.name }.joined(separator: ", "))")
        } else {
            logger.error("no session cookie available for websocket handshake, connecting to \(urlString) unauthenticated")
        }

        socket?.delegate = nil
        socket?.disconnect()
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
    }

    func disconnect() {
        shouldReconnect = false
        socket?.delegate = nil
        socket?.disconnect()
        socket = nil
        isConnected = false
    }

    private func scheduleReconnect() {
        guard shouldReconnect else { return }
        isConnected = false
        reconnectAttempt += 1
        let delay = min(pow(2.0, Double(min(reconnectAttempt, 5))), 30.0)
        logger.log("reconnecting in \(delay)s (attempt \(self.reconnectAttempt))")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.connect()
        }
    }

    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocketClient) {
      switch event {
      case .connected(let headers):
          isConnected = true
          reconnectAttempt = 0
          logger.log("connected \(headers)")
      case .disconnected(let reason, let closeCode):
          logger.log("disconnected \(reason) \(closeCode)")
          scheduleReconnect()
      case .text(let text):
          logger.log("received text (\(text.count) chars): \(text.prefix(500))")
          subject.send(text)
      case .binary(let data):
          logger.log("received data: \(data)")
      case .pong(let pongData):
          logger.log("received pong")
      case .ping(let pingData):
          logger.log("received ping")
      case .error(let error):
          logger.error("error \(String(describing: error))")
          scheduleReconnect()
      case .viabilityChanged:
          logger.log("viabilityChanged")
      case .reconnectSuggested:
          logger.log("reconnectSuggested")
          scheduleReconnect()
      case .cancelled:
          logger.log("cancelled")
          scheduleReconnect()
      }
    }
}
