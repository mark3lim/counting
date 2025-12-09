
//
//  ConnectivityProvider.swift
//  My Counting Watch App
//
//  Created by MARKLIM on 2025-12-07.
//
//  WatchConnectivity를 사용하여 iPhone과 데이터를 주고받는 클래스입니다.
//  데이터 전송(userInfo) 및 초기 데이터 요청(sendMessage)을 처리합니다.
//

import WatchConnectivity
import SwiftUI

@Observable
class ConnectivityProvider: NSObject, WCSessionDelegate {
    static let shared = ConnectivityProvider()
    
    // 데이터 수신 시 호출될 클로저
    var onReceiveCategories: (([TallyCategory]) -> Void)?
    var onReset: (() -> Void)?
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    // iPhone으로 데이터 전송
    func send(categories: [TallyCategory]) {
        guard WCSession.default.activationState == .activated else { return }
        do {
            let data = try JSONEncoder().encode(categories)
            // 백그라운드 전송을 위해 transferUserInfo 사용 (큐잉됨)
            WCSession.default.transferUserInfo(["categories": data])
        } catch {
            print("Failed to encode: \(error)")
        }
    }
    
    // 초기 데이터 요청
    func requestData() {
        // 1. 세션 인스턴스 가져오기
        let session = WCSession.default
        
        // 2. 연결 가능한 상태라면 즉시 메시지로 요청 (빠른 응답 기대)
        if session.activationState == .activated && session.isReachable {
            session.sendMessage(["request": "initialData"], replyHandler: { reply in
                self.handleIncoming(reply)
            }) { error in
                print("sendMessage failed: \(error). Fallback to transferUserInfo.")
                // 실패 시 transferUserInfo로 큐잉하여 재시도 (연결 시 자동 전송)
                session.transferUserInfo(["request": "initialData"])
            }
        } else {
            // 3. 연결 불가능하면 큐잉 전송 (연결 시 자동 전송됨)
            if session.activationState == .activated {
                session.transferUserInfo(["request": "initialData"])
            }
        }
    }
    
    // UserInfo 수신 (백그라운드 전송)
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        handleIncoming(userInfo)
    }
    
    // Message 수신 (실시간 전송)
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleIncoming(message)
    }
    
    // 수신 데이터 처리 로직
    private func handleIncoming(_ userInfo: [String: Any]) {
        // 리셋 명령 처리
        if let command = userInfo["command"] as? String, command == "reset" {
            DispatchQueue.main.async {
                self.onReset?()
            }
            return
        }
        
        if let data = userInfo["categories"] as? Data {
            if let decoded = try? JSONDecoder().decode([TallyCategory].self, from: data) {
                 DispatchQueue.main.async {
                     self.onReceiveCategories?(decoded)
                 }
            }
        }
        
        // 언어 설정 수신 처리
        if let languageCode = userInfo["language"] as? String {
            DispatchQueue.main.async {
                LocalizationManager.shared.setLanguage(from: languageCode)
            }
        }
    }
}
