//
//  countingApp.swift
//  counting
//
//  Created by MARKLIM on 2025-12-05.
//

import SwiftUI

// 앱의 진입점
// @main 어트리뷰트는 이 구조체가 앱의 시작점임을 나타냅니다.
@main
struct countingApp: App {
    @AppStorage("isLockEnabled") private var isLockEnabled = false
    @State private var isLocked = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                
                if isLocked {
                    LockView(isLocked: $isLocked)
                        .zIndex(1)
                        .transition(.opacity)
                }
            }
            .onAppear {
                if isLockEnabled {
                    isLocked = true
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                // 앱이 백그라운드로 가면 잠금 상태로 전환
                if newPhase == .background && isLockEnabled {
                    isLocked = true
                }
            }
        }
    }
}
