
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
            // 백그라운드나 비활성 상태(앱 전환기 등)로 진입 시 잠금하여 화면 보호
            if (newPhase == .background || newPhase == .inactive) && lockManager.isLockEnabled {
                lockManager.lock()
            }
        }
    }
}

extension View {
    func withLock() -> some View {
        self.modifier(LockViewModifier())
    }
}
