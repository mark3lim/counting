
import SwiftUI

struct LockViewModifier: ViewModifier {
    @ObservedObject var lockManager = LockManager.shared
    @Environment(\.scenePhase) var scenePhase
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if lockManager.isLocked {
                LockView(isLocked: Binding(
                    get: { lockManager.isLocked },
                    set: { lockManager.isLocked = $0 }
                ))
                .zIndex(999) // 가장 상단에 표시
                .transition(.opacity)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                // 백그라운드 진입 시 시간 기록 및 즉시 잠금
                if lockManager.isLockEnabled {
                    lockManager.registerBackgroundEntry()
                }
            } else if newPhase == .active {
                // 활성 상태 복귀 시 잠금 시간 초과 여부 확인
                if lockManager.isLockEnabled {
                    lockManager.checkLockRequirement()
                }
            }
        }
    }
}

extension View {
    func withLock() -> some View {
        self.modifier(LockViewModifier())
    }
}
