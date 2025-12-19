import Foundation
import Combine
import WatchConnectivity
import UIKit

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
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion?(false) }
                return
            }
            
            guard let encoded = try? JSONEncoder().encode(categories) else {
                DispatchQueue.main.async { completion?(false) }
                return
            }
            self.sendData([self.kCategories: encoded], completion: completion)
        }
    }
    
    /// Sends the current language to the Watch.
    func sendLanguage(_ languageCode: String) {
        sendData([kLanguage: languageCode])
    }
    
    private func sendData(_ userInfo: [String: Any], completion: ((Bool) -> Void)? = nil) {
        guard WCSession.default.activationState == .activated else {
            DispatchQueue.main.async { completion?(false) }
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
        
        DispatchQueue.main.async {
            completion?(true)
        }
    }
}

// MARK: - WCSessionDelegate
extension ConnectivityProvider: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    // iOS specific required delegate methods
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    
    // MARK: - Receiving Data
    
    private func processReceivedData(_ data: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
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
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        processReceivedData(message)
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        processReceivedData(userInfo)
    }
}
