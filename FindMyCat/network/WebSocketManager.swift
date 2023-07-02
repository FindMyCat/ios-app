//
//  WebSocketManager.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/25/23.
//

import Starscream
import Combine
import Foundation

class WebSocketManager: WebSocketDelegate {

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
        print("connected \(headers)")
      case .disconnected(let reason, let closeCode):
        print("disconnected \(reason) \(closeCode)")
      case .text(let text):
//        print("received text: \(text)")
        subject.send(text)
      case .binary(let data):
        print("received data: \(data)")
      case .pong(let pongData):
        print("received pong: \(pongData)")
      case .ping(let pingData):
        print("received ping: \(pingData)")
      case .error(let error):
        print("error \(error)")
      case .viabilityChanged:
        print("viabilityChanged")
      case .reconnectSuggested:
        print("reconnectSuggested")
      case .cancelled:
          socket?.connect()
        print("cancelled")
      }
    }
}
