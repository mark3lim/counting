
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
            DispatchQueue.main.async {
                if let categories = self.dataSource?() {
                    self.send(categories: categories)
                }
            }
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
    
    // 언어 설정 전송 메서드 추가
    func sendLanguage(_ languageCode: String) {
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        
        session.transferUserInfo(["language": languageCode])
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        if userInfo["request"] as? String == "initialData" {
            // 요청을 받으면 현재 데이터를 전송 (마찬가지로 큐잉되어 전송됨)
            DispatchQueue.main.async { // dataSource 접근 위해 메인 스레드
                if let categories = self.dataSource?() {
                    self.send(categories: categories)
                }
            }
        } else {
            handleIncoming(userInfo)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if message["request"] as? String == "initialData" {
            // 메인 스레드에서 데이터 안전하게 접근
            DispatchQueue.main.async {
                if let categories = self.dataSource?() {
                    do {
                        let data = try JSONEncoder().encode(categories)
                        replyHandler(["categories": data])
                    } catch {
                        replyHandler(["error": error.localizedDescription])
                    }
                } else {
                    replyHandler(["error": "No data source available"])
                }
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
