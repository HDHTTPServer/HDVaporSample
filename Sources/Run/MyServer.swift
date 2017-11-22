//
//  MyServer.swift
//  App
//
//  Created by ST21073 on 2017/11/22.
//

import Vapor
import FluentProvider
import HTTP
import HDHTTPServer
import Sockets

extension TCPInternetSocket: ClientSocket {}

extension SSSocket: Sockets.Socket {
    public var config: Sockets.Config {
        return Sockets.Config.TCP()
    }
    public var descriptor: Descriptor {
        return Descriptor(integerLiteral: socketfd)
    }
    public var isClosed: Bool {
        return false
    }
    public func close() throws {
        // DO NOTHING
    }
}

class MySocketHander: ClientSocketHandler {
    var isClosing: Bool {
        return false
    }

    func softClose() {
    }

    typealias Socket = TCPInternetSocket

    private var mySocket: TCPInternetSocket?
    var myResponder: Responder?

    var isOpen: Bool {
        return true
    }

    required init() {
    }

    func handle(socket: TCPInternetSocket) throws {
        guard let responder = myResponder else {
            print("no responder")
            return
        }

        mySocket = socket

        try socket.setTimeout(defaultServerTimeout)

        var buffer = Bytes(repeating: 0, count: 2048)

        let parser = RequestParser()
        let serializer = ResponseSerializer()

        defer {
            try? socket.close()
        }

        var keepAlive = false
        main: repeat {
            var request: Request?

            while request == nil {
                let read = try socket.read(max: buffer.count, into: &buffer)
                guard read > 0 else {
                    break main
                }
                request = try parser.parse(max: read, from: buffer)
            }

            guard let req = request else {
                print("Could not parse a request from the stream")
                throw ParserError.invalidMessage
            }

            // set the stream for peer information
            req.stream = socket

            keepAlive = req.keepAlive
            let response = try responder.respond(to: req)

            while true {
                let length = try serializer.serialize(response, into: &buffer)
                guard length > 0 else {
                    break
                }
                let written = try socket.write(max: length, from: buffer)
                guard written == length else {
                    // FIXME: better error
                    print("Could not write all bytes to the stream")
                    throw StreamError.closed
                }
            }

            switch response.body {
            case .chunked(let closure):
                let chunk = ChunkStream(socket)
                try closure(chunk)
            case .data(let bytes):
                _ = try socket.write(bytes)
            }

            try response.onComplete?(socket)
        } while keepAlive && !socket.isClosed
    }

    func close() {
        do {
            try mySocket?.close()
        } catch {
            print("close socket failed")
        }
    }

    func closeIfIdleSocket() {
    }
}

class MySocketManager: ClientSocketHandlerManager {
    typealias Handler = MySocketHander

    private var handlers = [Handler]()
    var responder: Responder?
    private var listener: TCPInternetSocket?

    var count: Int {
        return handlers.count
    }

    func add(handler: MySocketHander) {
        handler.myResponder = responder
        handlers.append(handler)
    }

    func closeAll() {
        handlers.forEach { (handler) in
            handler.close()
        }

        handlers.removeAll()
    }

    func prune() {
        closeAll()
    }

    func acceptClientConnection(serverSocket: SSSocket) -> TCPInternetSocket? {
        print("start accept")

        if listener == nil {
            let config = Sockets.Config.TCP()
            let descriptor = Descriptor(integerLiteral: serverSocket.socketfd)
            let resolved = try! serverSocket.localAddress()

            listener = try! TCPInternetSocket(descriptor, config, resolved)
        }

        return try! listener!.accept()
    }
}

class MyServer: ServerProtocol {
    private let server: HDHTTPServer<MySocketManager>
    private let hostName: String
    private let port: UInt16
    private let socketManager: MySocketManager

    required init(hostname: String, port: UInt16, _ securityLayer: SecurityLayer) throws {
//        let sock_fd = socket(AF_INET, SOCK_STREAM, 0);
//
//        guard sock_fd != -1 else {
//            throw Abort.serverError
//        }

        self.hostName = hostname
        self.port = port
        self.socketManager = MySocketManager()
        self.server = HDHTTPServer(serverSocket: SSSocket()!,
                                   clientSocketHandlerManager: self.socketManager)
    }

    func start(_ responder: Responder, errors: @escaping ServerErrorHandler) throws {
        print("start listening")
        socketManager.responder = responder
        try server.start(port: self.port)
    }
}

class MyServerFactory: ServerFactoryProtocol {
    func makeServer(hostname: String, port: Port, _ securityLayer: SecurityLayer) throws -> ServerProtocol {
        return try! MyServer(hostname: hostname, port: port, securityLayer)
    }
}
