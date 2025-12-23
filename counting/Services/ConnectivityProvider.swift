import Foundation
import Combine
import WatchConnectivity
import UIKit

@MainActor
class ConnectivityProvider: NSObject, ObservableObject {
    static let shared = ConnectivityProvider()
    
    // Constants
    private let kCategories = "categories"
    private let kLanguage = "language"
    
    // Callbacks for Models.swift to hook into
    var onReceiveCategories: (([TallyCategory]) -> Void)?
    var onReceiveLanguage: ((String) -> Void)?
    var onRequestData: (() -> Void)?
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    /// Checks if the WCSession is currently activated.
    func isSessionActivated() -> Bool {
        return WCSession.default.activationState == .activated
    }
    
    // MARK: - Sending Data
    
    /// Sends the current categories to the Watch.
    func send(categories: [TallyCategory], completion: ((Bool) -> Void)? = nil) {
        // Run on background to avoid blocking UI during encoding
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let encoded = try? JSONEncoder().encode(categories) else {
                await self?.handleCompletion(completion, success: false)
                return
            }
            // Switch back to MainActor to access self and sendData
            await self?.sendData([self?.kCategories ?? "categories": encoded], completion: completion)
        }
    }
    
    /// Sends the current language to the Watch.
    func sendLanguage(_ languageCode: String) {
        sendData([kLanguage: languageCode])
    }
    
    private func sendData(_ userInfo: [String: Any], completion: ((Bool) -> Void)? = nil) {
        guard WCSession.default.activationState == .activated else {
            completion?(false)
            return
        }
        
        // We consider the operation "initiated" successfully if we hand off to WCSession.
        // Real-time delivery confirmation requires replyHandler implementation on Watch side.
        // For now, we report success purely on "request sent/queued".
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(userInfo, replyHandler: nil) { error in
                // Fallback to transferUserInfo on error
                WCSession.default.transferUserInfo(userInfo)
            }
        } else {
            WCSession.default.transferUserInfo(userInfo)
        }
        
        completion?(true)
    }
    
    // Helper to handle completion on MainActor
    private func handleCompletion(_ completion: ((Bool) -> Void)?, success: Bool) {
        completion?(success)
    }
}

// MARK: - WCSessionDelegate
extension ConnectivityProvider: WCSessionDelegate {
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    // iOS specific required delegate methods
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    
    // MARK: - Receiving Data
    
    private func processReceivedData(_ data: [String: Any]) {
        // 이미 MainActor 컨텍스트인 경우 바로 실행, 아니면 Task로 감싸서 실행
        // processReceivedData는 delegate에서 호출되므로 Task { @MainActor } 필요
        Task { @MainActor [weak self] in
            if let encodedData = data[self?.kCategories ?? "categories"] as? Data {
                if let receivedCategories = try? JSONDecoder().decode([TallyCategory].self, from: encodedData) {
                    self?.onReceiveCategories?(receivedCategories)
                }
            }
            
            if let languageCode = data[self?.kLanguage ?? "language"] as? String {
                self?.onReceiveLanguage?(languageCode)
            }
            
            if data["requestInitialData"] as? Bool == true {
                self?.onRequestData?()
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            self.processReceivedData(message)
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        Task { @MainActor in
            self.processReceivedData(userInfo)
        }
    }
}
