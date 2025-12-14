import Foundation
import Combine
import WatchConnectivity

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
        guard let encoded = try? JSONEncoder().encode(categories) else { return }
        sendData([kCategories: encoded])
    }
    
    func sendLanguage(_ languageCode: String) {
        sendData([kLanguage: languageCode])
    }
    
    private func sendData(_ userInfo: [String: Any]) {
        guard WCSession.default.activationState == .activated else {
            print("WCSession is not activated")
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
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WCSession activated (Watch): \(activationState.rawValue)")
    }
    
    // WatchOS does not have sessionDidBecomeInactive or sessionDidDeactivate
    
    // MARK: - Receiving Data
    
    private func processReceivedData(_ data: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            if let encodedData = data[self?.kCategories ?? "categories"] as? Data {
                if let receivedCategories = try? JSONDecoder().decode([TallyCategory].self, from: encodedData) {
                    print("Received \(receivedCategories.count) categories from iOS")
                    self?.onReceiveCategories?(receivedCategories)
                }
            }
            
            if let languageCode = data[self?.kLanguage ?? "language"] as? String {
                self?.onReceiveLanguage?(languageCode)
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        processReceivedData(message)
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        processReceivedData(userInfo)
    }
}
