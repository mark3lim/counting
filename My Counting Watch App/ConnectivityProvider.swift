
import WatchConnectivity
import SwiftUI

@Observable
class ConnectivityProvider: NSObject, WCSessionDelegate {
    static let shared = ConnectivityProvider()
    
    var onReceiveCategories: (([TallyCategory]) -> Void)?
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    func send(categories: [TallyCategory]) {
        guard WCSession.default.activationState == .activated else { return }
        do {
            let data = try JSONEncoder().encode(categories)
            WCSession.default.transferUserInfo(["categories": data])
        } catch {
            print("Failed to encode: \(error)")
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        handleIncoming(userInfo)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleIncoming(message)
    }
    
    private func handleIncoming(_ userInfo: [String: Any]) {
        if let data = userInfo["categories"] as? Data {
            if let decoded = try? JSONDecoder().decode([TallyCategory].self, from: data) {
                 DispatchQueue.main.async {
                     self.onReceiveCategories?(decoded)
                 }
            }
        }
    }
}
