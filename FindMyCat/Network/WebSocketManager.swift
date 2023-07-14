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

    let urlString = "ws://ec2-18-191-185-127.us-east-2.compute.amazonaws.com:8082/api/socket"

    private var socket: WebSocket?
    private var cancellables = Set<AnyCancellable>()

    private var isConnected: Bool = false
    private let subject = PassthroughSubject<String, Never>()

    var dataPublisher: AnyPublisher<String, Never> {
        return subject.eraseToAnyPublisher()
    }

    func connect() {
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
    }

    func disconnect() {
        socket?.disconnect()
        socket = nil
    }

    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocketClient) {
      switch event {
      case .connected(let headers):
          logger.log("connected \(headers)")
      case .disconnected(let reason, let closeCode):
          logger.log("disconnected \(reason) \(closeCode)")
      case .text(let text):
          subject.send(text)
      case .binary(let data):
          logger.log("received data: \(data)")
      case .pong(let pongData):
          logger.log("received pong")
      case .ping(let pingData):
          logger.log("received ping")
      case .error(let error):
          logger.error("error \(error)")
      case .viabilityChanged:
          logger.log("viabilityChanged")
      case .reconnectSuggested:
          logger.log("reconnectSuggested")
      case .cancelled:
          socket?.connect()
          logger.log("cancelled")
      }
    }
}
