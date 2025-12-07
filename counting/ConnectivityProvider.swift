
import WatchConnectivity
import Combine
import Foundation

class ConnectivityProvider: NSObject, WCSessionDelegate {
    static let shared = ConnectivityProvider()
    
    var onReceiveCategories: (([TallyCategory]) -> Void)?
    var dataSource: (() -> [TallyCategory])?
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // 세션 활성화 시 데이터 전송 시도
        if activationState == .activated {
           // 필요 시 여기서 초기 데이터 전송 가능
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) { }
    
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    
    func send(categories: [TallyCategory]) {
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        
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
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if message["request"] as? String == "initialData" {
            if let categories = dataSource?() {
                do {
                    let data = try JSONEncoder().encode(categories)
                    replyHandler(["categories": data])
                } catch {
                    replyHandler(["error": error.localizedDescription])
                }
            } else {
                replyHandler(["error": "No data source available"])
            }
        } else {
            handleIncoming(message)
            replyHandler([:])
        }
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
