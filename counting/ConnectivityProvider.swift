
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
    
    // 리셋 명령 전송
    func sendReset() {
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        session.transferUserInfo(["command": "reset"])
    }
    
    // 언어 설정 전송 메서드
    // - Parameter languageCode: 전송할 언어 코드 (예: "ko", "en")
    // 참고: 세션이 활성화되지 않은 경우 전송되지 않습니다.
    func sendLanguage(_ languageCode: String) {
        // WCSession 지원 여부 확인
        guard WCSession.isSupported() else { return }
        
        let session = WCSession.default
        
        // 세션이 활성화된 경우에만 전송
        if session.activationState == .activated {
            session.transferUserInfo(["language": languageCode])
        } else {
            // 활성화되지 않은 경우, 활성화 후 전송되도록 (필요시 큐잉 로직 추가 가능하나, 
            // 현재 구조상 activationDidCompleteWith에서 처리하거나 단순 반환)
            // 여기서는 안전하게 반환하여 크래시 방지
            print("WCSession not activated, skipping language sync")
        }
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
        // 카테고리 데이터 수신 처리
        if let data = userInfo["categories"] as? Data {
            DispatchQueue.main.async {
                if let categories = try? JSONDecoder().decode([TallyCategory].self, from: data) {
                    self.onReceiveCategories?(categories)
                }
            }
        }
        
        // 언어 설정 수신 처리 (Watch -> iPhone 인 경우 등 상호 동기화 시 필요)
        // 현재 iPhone -> Watch 단방향 설정이 주된 흐름이나, 확장성을 위해 처리 로직 추가
        if let languageCode = userInfo["language"] as? String {
             DispatchQueue.main.async {
                 LocalizationManager.shared.setLanguage(from: languageCode)
             }
        }
    }
}
