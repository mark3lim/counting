import SwiftUI
import Combine
import LocalAuthentication
import CryptoKit

class LockManager: ObservableObject {
    static let shared = LockManager()
    
    @AppStorage("isLockEnabled") var isLockEnabled = false
    @AppStorage("useFaceID") var useFaceID = false
    @Published var isLocked = false
    
    // Auth related
    private var isAuthenticating = false
    
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
