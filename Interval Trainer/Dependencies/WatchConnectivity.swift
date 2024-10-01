//
//  WatchConnectivity.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/28/24.
//

import Foundation
import WatchConnectivity
import Dependencies

struct WatchConnectivityClient {
    var send: @Sendable (_ message: [String: Any]) -> Void
    var receive: @Sendable () -> AsyncStream<[String: Any]>
}

extension WatchConnectivityClient: DependencyKey {
    static let liveValue: Self = {
        let session = WCSession.default
        let subject = AsyncStream<[String: Any]>.makeStream()
        
        class Delegate: NSObject, WCSessionDelegate {
            let continuation: AsyncStream<[String: Any]>.Continuation
            
            init(continuation: AsyncStream<[String: Any]>.Continuation) {
                self.continuation = continuation
            }
            
            func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
            
            func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
                continuation.yield(message)
            }
            
            #if os(iOS)
            func sessionDidBecomeInactive(_ session: WCSession) {}
            func sessionDidDeactivate(_ session: WCSession) {}
            #endif
        }
        
        let delegate = Delegate(continuation: subject.continuation)
        session.delegate = delegate
        session.activate()
        
        return Self(
            send: { message in
                guard session.activationState == .activated else { return }
                #if os(iOS)
                if session.isReachable {
                    session.sendMessage(message, replyHandler: nil)
                }
                #else
                session.sendMessage(message, replyHandler: nil)
                #endif
            },
            receive: { subject.stream }
        )
    }()
}

extension DependencyValues {
    var watchConnectivity: WatchConnectivityClient {
        get { self[WatchConnectivityClient.self] }
        set { self[WatchConnectivityClient.self] = newValue }
    }
}
