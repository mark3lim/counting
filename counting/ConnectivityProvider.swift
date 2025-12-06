
import WatchConnectivity
import Combine
import Foundation

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
    
    func sessionDidBecomeInactive(_ session: WCSession) { }
    
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    
    func send(categories: [TallyCategory]) {
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        // 워치가 페어링되어 있고, 앱이 설치된 경우에만 전송
        guard session.isPaired && session.isWatchAppInstalled else { return }
        
        do {
            let data = try JSONEncoder().encode(categories)
            session.transferUserInfo(["categories": data])
        } catch {
            print("Error encoding categories: \(error)")
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
            DispatchQueue.main.async {
                if let categories = try? JSONDecoder().decode([TallyCategory].self, from: data) {
                    self.onReceiveCategories?(categories)
                }
            }
        }
    }
}
