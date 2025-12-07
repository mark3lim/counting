
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
    
    func requestData() {
        // 1. 세션이 활성화되지 않았다면 아무것도 할 수 없음 (하지만 transferUserInfo는 큐잉 가능하므로 시도)
        let session = WCSession.default
        
        // 2. 연결 가능한 상태라면 즉시 메시지로 요청 (빠른 응답)
        if session.activationState == .activated && session.isReachable {
            session.sendMessage(["request": "initialData"], replyHandler: { reply in
                self.handleIncoming(reply)
            }) { error in
                print("sendMessage failed: \(error). Fallback to transferUserInfo.")
                // 실패 시 큐잉 전송
                session.transferUserInfo(["request": "initialData"])
            }
        } else {
            // 3. 연결 불가능하면 큐잉 전송 (연결 시 자동 전송됨)
            if session.activationState == .activated {
                session.transferUserInfo(["request": "initialData"])
            }
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
