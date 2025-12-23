import Foundation
import Combine
import WatchConnectivity

@MainActor
class ConnectivityProvider: NSObject, ObservableObject {
    static let shared = ConnectivityProvider()
    
    // Constants
    private let kCategories = "categories"
    private let kLanguage = "language"
    
    // Callbacks for Models.swift to hook into
    var onReceiveCategories: (([TallyCategory]) -> Void)?
    var onReceiveLanguage: ((String) -> Void)?
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    // MARK: - Sending Data
    
    /// Sends the current categories to the iOS App.
    func send(categories: [TallyCategory]) {
        // Encodable이 Sendable을 보장하면 Task.detached로 보내도 안전.
        // TallyCategory는 이제 Sendable임.
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let encoded = try? JSONEncoder().encode(categories) else { return }
            await self?.sendData([self?.kCategories ?? "categories": encoded])
        }
    }
    
    func sendLanguage(_ languageCode: String) {
        sendData([kLanguage: languageCode])
    }
    
    func requestInitialData() {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["requestInitialData": true], replyHandler: nil)
        }
    }
    
    private func sendData(_ userInfo: [String: Any]) {
        guard WCSession.default.activationState == .activated else {
            return
        }
        
        // 1. Try Real-time
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(userInfo, replyHandler: nil) { error in
                WCSession.default.transferUserInfo(userInfo)
            }
        } else {
            // 2. Queue for background/later
            WCSession.default.transferUserInfo(userInfo)
        }
    }
}

// MARK: - WCSessionDelegate
extension ConnectivityProvider: WCSessionDelegate {
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    // WatchOS does not have sessionDidBecomeInactive or sessionDidDeactivate
    
    // MARK: - Receiving Data
    
    private func processReceivedData(_ data: [String: Any]) {
        // 이미 MainActor context
        if let encodedData = data[self.kCategories] as? Data {
            if let receivedCategories = try? JSONDecoder().decode([TallyCategory].self, from: encodedData) {
                self.onReceiveCategories?(receivedCategories)
            }
        }
        
        if let languageCode = data[self.kLanguage] as? String {
            self.onReceiveLanguage?(languageCode)
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
