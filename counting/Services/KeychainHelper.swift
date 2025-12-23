
//
//  KeychainHelper.swift
//  counting
//
//  Created by MARKLIM on 2025-12-07.
//
//  Keychain 접근을 돕는 헬퍼 클래스입니다.
//  비밀번호 등 민감한 데이터를 안전하게 저장, 조회, 삭제하는 기능을 제공합니다.
//

import Foundation
import Foundation
import Security

final class KeychainHelper: Sendable {
    static let shared = KeychainHelper()
    private let service = "com.mark3lim.counting.pin" // Keychain 서비스 식별자
    private let account = "userPin" // 저장할 데이터의 계정 키
    
    // 데이터를 Keychain에 저장합니다.
    // - Parameter data: 저장할 데이터 (Data 타입)
    // - Returns: 저장 성공 여부 (Bool)
    @discardableResult
    func save(_ data: Data) -> Bool {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data
        ] as [String: Any]
        
        // 기존 데이터가 있다면 삭제 후 저장 (덮어쓰기)
        SecItemDelete(query as CFDictionary)
        
        // 새로운 데이터 추가
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // 문자열(PIN)을 Keychain에 저장하는 편의 메서드입니다.
    // - Parameter pin: 저장할 문자열
    // - Returns: 저장 성공 여부
    @discardableResult
    func savePin(_ pin: String) -> Bool {
        if let data = pin.data(using: .utf8) {
            return save(data)
        }
        return false
    }
    
    // Keychain에서 데이터를 불러옵니다.
    // - Returns: 저장된 데이터 (없으면 nil)
    func read() -> Data? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true, // 데이터 반환 요청
            kSecMatchLimit: kSecMatchLimitOne // 하나의 결과만 매칭
        ] as [String: Any]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            return dataTypeRef as? Data
        }
        return nil
    }
    
    // Keychain에서 PIN 문자열을 불러오는 편의 메서드입니다.
    // - Returns: 저장된 PIN 문자열 (없으면 nil)
    func readPin() -> String? {
        if let data = read() {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    // Keychain에 저장된 데이터를 삭제합니다.
    func delete() {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as [String: Any]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // PIN 번호가 저장되어 있는지 확인합니다.
    // - Returns: 존재하면 true, 아니면 false
    func hasPin() -> Bool {
        return read() != nil
    }
}
