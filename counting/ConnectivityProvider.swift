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
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    // MARK: - Sending Data
    
    /// Sends the current categories to the Watch.
    func send(categories: [TallyCategory]) {
        guard let encoded = try? JSONEncoder().encode(categories) else { return }
        sendData([kCategories: encoded])
    }
    
    /// Sends the current language to the Watch.
    func sendLanguage(_ languageCode: String) {
        sendData([kLanguage: languageCode])
    }
    
    private func sendData(_ userInfo: [String: Any]) {
        guard WCSession.default.activationState == .activated else {
            print("WCSession is not activated")
            return
        }
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(userInfo, replyHandler: nil) { error in
                // Fallback to transferUserInfo
                WCSession.default.transferUserInfo(userInfo)
            }
        } else {
            WCSession.default.transferUserInfo(userInfo)
        }
    }
}

// MARK: - WCSessionDelegate
extension ConnectivityProvider: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WCSession activated (iOS): \(activationState.rawValue)")
    }
    
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
                    print("Received \(receivedCategories.count) categories from Watch")
                    self?.onReceiveCategories?(receivedCategories)
                }
            }
            
            if let languageCode = data[self?.kLanguage ?? "language"] as? String {
                print("Received language from Watch: \(languageCode)")
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
