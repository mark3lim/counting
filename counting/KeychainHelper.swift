
import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()
    private let service = "com.mark3lim.counting.pin" // 고유 서비스 식별자
    private let account = "userPin"
    
    // 저장 (성공 시 true 반환)
    @discardableResult
    func save(_ data: Data) -> Bool {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data
        ] as [String: Any]
        
        // 기존 데이터 삭제 후 저장 (덮어쓰기)
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // 문자열 저장 편의 메서드
    @discardableResult
    func savePin(_ pin: String) -> Bool {
        if let data = pin.data(using: .utf8) {
            return save(data)
        }
        return false
    }
    
    // 불러오기
    func read() -> Data? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as [String: Any]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            return dataTypeRef as? Data
        }
        return nil
    }
    
    // 문자열 불러오기 편의 메서드
    func readPin() -> String? {
        if let data = read() {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    // 삭제
    func delete() {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as [String: Any]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // 핀 존재 여부 확인
    func hasPin() -> Bool {
        return read() != nil
    }
}
