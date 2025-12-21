import SwiftUI
import Combine
import LocalAuthentication
import CryptoKit

class LockManager: ObservableObject {
    static let shared = LockManager()
    
    @AppStorage("isLockEnabled") var isLockEnabled = false
    @AppStorage("useFaceID") var useFaceID = false
    @AppStorage("lockTimeout") var lockTimeout: Int = 0 // 0: Immediate, unit: seconds
    
    @Published var isLocked = false
    
    // Auth related
    private var isAuthenticating = false
    private var backgroundEnterTime: Date?
    
    private init() {
        if isLockEnabled {
            isLocked = true
        }
    }
    
    func lock() {
        if isLockEnabled {
            withAnimation {
                isLocked = true
            }
        }
    }
    
    // 백그라운드 진입 시점 기록
    func registerBackgroundEntry() {
        backgroundEnterTime = Date()
        
        // "즉시" 설정(0초)인 경우 바로 잠금 처리하여 앱 전환기에서 화면 보호
        if lockTimeout == 0 && isLockEnabled {
            lock()
        }
    }
    
    // 포그라운드 복귀 시 잠금 및 인증 필요 여부 확인
    func checkLockRequirement() {
        // 1. 이미 잠겨있는 경우 (앱 실행 직후 또는 "즉시" 잠금 상태)
        if isLocked {
            backgroundEnterTime = nil
            authenticate()
            return
        }
        
        // 2. 잠겨있지 않은 경우: 타임아웃 체크
        guard isLockEnabled, let enterTime = backgroundEnterTime else { return }
        
        let elapsed = Date().timeIntervalSince(enterTime)
        if elapsed >= Double(lockTimeout) {
            lock()
            authenticate() // 잠금과 동시에 인증 시도
        }
        
        backgroundEnterTime = nil
    }
    
    func unlock() {
        withAnimation {
            isLocked = false
        }
    }
    
    func validatePin(_ pin: String) -> Bool {
        guard let storedPin = KeychainHelper.shared.readPin() else { return false }
        return constantTimeCompare(storedPin, pin)
    }
    
    func authenticate() {
        guard isLockEnabled, useFaceID, isLocked, !isAuthenticating else { return }
        
        isAuthenticating = true
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "unlock_reason".localized
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, _ in
                DispatchQueue.main.async {
                    self?.isAuthenticating = false
                    if success {
                        self?.unlock()
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.isAuthenticating = false
            }
        }
    }
    
    // Constant-time comparison using CryptoKit to prevent timing attacks
    // Using SHA256 hashing ensures that we compare fixed-length digests,
    // mitigating timing leaks related to the input length.
    private func constantTimeCompare(_ lhs: String, _ rhs: String) -> Bool {
        guard let lhsData = lhs.data(using: .utf8),
              let rhsData = rhs.data(using: .utf8) else {
            return false
        }
        
        // Compute SHA256 hashes (constant output size)
        let lhsDigest = SHA256.hash(data: lhsData)
        let rhsDigest = SHA256.hash(data: rhsData)
        
        // Compare digests (constant time)
        return lhsDigest == rhsDigest
    }
}
