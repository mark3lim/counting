//
//  L2CAPDataModel.swift
//  counting
//
//  Created by MARKLIM on 2025-12-19.
//
//  L2CAP 통신을 위한 데이터 모델 정의
//

import Foundation
import CoreBluetooth
import CommonCrypto // CommonCrypto import (SHA-1 사용을 위해 필요)

// MARK: - L2CAP 메시지 타입
enum L2CAPMessageType: UInt8, Codable, Sendable {
    case sync = 0x01           // 데이터 동기화
    case request = 0x02        // 데이터 요청
    case response = 0x03       // 응답
    case heartbeat = 0x04      // 연결 유지
    case error = 0xFF          // 에러
}

// MARK: - L2CAP 메시지 프로토콜
protocol L2CAPMessage: Codable, Sendable {
    var type: L2CAPMessageType { get }
    var timestamp: Date { get }
}

// MARK: - 동기화 메시지
struct L2CAPSyncMessage: L2CAPMessage, Sendable {
    let type: L2CAPMessageType
    let timestamp: Date
    let categories: [TallyCategory]
    
    init(categories: [TallyCategory], timestamp: Date = Date()) {
        self.type = .sync
        self.timestamp = timestamp
        self.categories = categories
    }
    
    // Manual Codable implementation to avoid MainActor isolation
    enum CodingKeys: String, CodingKey {
        case type, timestamp, categories
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(L2CAPMessageType.self, forKey: .type)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.categories = try container.decode([TallyCategory].self, forKey: .categories)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(categories, forKey: .categories)
    }
}

// MARK: - 요청 메시지
struct L2CAPRequestMessage: L2CAPMessage, Sendable {
    let type: L2CAPMessageType
    let timestamp: Date
    let requestType: RequestType
    
    enum RequestType: String, Codable, Sendable {
        case fullSync
        case categoryUpdate
        case counterUpdate
    }
    
    init(requestType: RequestType, timestamp: Date = Date()) {
        self.type = .request
        self.timestamp = timestamp
        self.requestType = requestType
    }
    
    enum CodingKeys: String, CodingKey {
        case type, timestamp, requestType
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(L2CAPMessageType.self, forKey: .type)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.requestType = try container.decode(RequestType.self, forKey: .requestType)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(requestType, forKey: .requestType)
    }
}

// MARK: - 응답 메시지
struct L2CAPResponseMessage: L2CAPMessage, Sendable {
    let type: L2CAPMessageType
    let timestamp: Date
    let success: Bool
    let message: String?
    
    init(success: Bool, message: String? = nil, timestamp: Date = Date()) {
        self.type = .response
        self.timestamp = timestamp
        self.success = success
        self.message = message
    }
    
    enum CodingKeys: String, CodingKey {
        case type, timestamp, success, message
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(L2CAPMessageType.self, forKey: .type)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.success = try container.decode(Bool.self, forKey: .success)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(success, forKey: .success)
        try container.encodeIfPresent(message, forKey: .message)
    }
}

// MARK: - 하트비트 메시지
struct L2CAPHeartbeatMessage: L2CAPMessage, Sendable {
    let type: L2CAPMessageType
    let timestamp: Date
    
    init(timestamp: Date = Date()) {
        self.type = .heartbeat
        self.timestamp = timestamp
    }
    
    enum CodingKeys: String, CodingKey {
        case type, timestamp
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(L2CAPMessageType.self, forKey: .type)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
    }
}

// MARK: - 에러 메시지
struct L2CAPErrorMessage: L2CAPMessage, Sendable {
    let type: L2CAPMessageType
    let timestamp: Date
    let errorCode: Int
    let errorDescription: String
    
    init(errorCode: Int, errorDescription: String, timestamp: Date = Date()) {
        self.type = .error
        self.timestamp = timestamp
        self.errorCode = errorCode
        self.errorDescription = errorDescription
    }
    
    enum CodingKeys: String, CodingKey {
        case type, timestamp, errorCode, errorDescription
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(L2CAPMessageType.self, forKey: .type)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.errorCode = try container.decode(Int.self, forKey: .errorCode)
        self.errorDescription = try container.decode(String.self, forKey: .errorDescription)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(errorCode, forKey: .errorCode)
        try container.encode(errorDescription, forKey: .errorDescription)
    }
}

// MARK: - 메시지 인코더/디코더
class L2CAPMessageCoder {
    
    /// 메시지를 Data로 인코딩
    static func encode<T: L2CAPMessage>(_ message: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(message)
    }
    
    /// Data를 메시지로 디코딩
    static func decode(_ data: Data) throws -> any L2CAPMessage {
        // 먼저 메시지 타입 확인
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // 타입 추출을 위한 임시 구조체
        struct MessageTypeWrapper: Codable {
            let type: L2CAPMessageType
        }
        
        let wrapper = try decoder.decode(MessageTypeWrapper.self, from: data)
        
        // 타입에 따라 적절한 메시지로 디코딩
        switch wrapper.type {
        case .sync:
            return try decoder.decode(L2CAPSyncMessage.self, from: data)
        case .request:
            return try decoder.decode(L2CAPRequestMessage.self, from: data)
        case .response:
            return try decoder.decode(L2CAPResponseMessage.self, from: data)
        case .heartbeat:
            return try decoder.decode(L2CAPHeartbeatMessage.self, from: data)
        case .error:
            return try decoder.decode(L2CAPErrorMessage.self, from: data)
        }
    }
}

// MARK: - 블루투스 기기 정보
// MARK: - 블루투스 기기 정보
struct BluetoothDeviceInfo: Identifiable, Hashable, @unchecked Sendable {
    let id: UUID
    let name: String
    let rssi: Int
    let peripheral: CBPeripheral
    
    init(peripheral: CBPeripheral, rssi: Int = 0) {
        self.id = peripheral.identifier
        self.name = peripheral.name ?? "Unknown Device"
        self.rssi = rssi
        self.peripheral = peripheral
    }
    
    // Hashable 구현
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: BluetoothDeviceInfo, rhs: BluetoothDeviceInfo) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - L2CAP 설정
struct L2CAPConfiguration {
    /// Bundle Identifier 기반 UUID 생성
    /// 같은 앱은 항상 같은 UUID를 가지지만, 다른 앱은 다른 UUID를 가짐
    private static func generateUUID(namespace: String, name: String) -> CBUUID {
        // UUID v5 방식: 네임스페이스 UUID + 이름을 SHA-1 해싱하여 UUID 생성
        let namespaceUUID = UUID(uuidString: namespace)!
        
        // 네임스페이스 UUID와 이름을 결합
        var namespaceBytes = withUnsafeBytes(of: namespaceUUID.uuid) { Array($0) }
        let nameBytes = Array(name.utf8)
        namespaceBytes.append(contentsOf: nameBytes)
        
        // SHA-1 해시 생성
        let hash = Data(namespaceBytes).sha1Hash()
        
        // UUID 형식으로 변환 (버전 5, variant 10)
        var uuidBytes = Array(hash.prefix(16))
        uuidBytes[6] = (uuidBytes[6] & 0x0F) | 0x50  // Version 5
        uuidBytes[8] = (uuidBytes[8] & 0x3F) | 0x80  // Variant 10
        
        // UUID 문자열 생성
        let uuidString = String(format: "%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X",
                               uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3],
                               uuidBytes[4], uuidBytes[5], uuidBytes[6], uuidBytes[7],
                               uuidBytes[8], uuidBytes[9], uuidBytes[10], uuidBytes[11],
                               uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15])
        
        return CBUUID(string: uuidString)
    }
    
    /// 서비스 UUID (Bundle Identifier 기반으로 자동 생성)
    static let serviceUUID: CBUUID = {
        // Bundle Identifier 가져오기
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.default.app"
        
        // DNS 네임스페이스 UUID (RFC 4122 표준)
        let dnsNamespace = "6ba7b810-9dad-11d1-80b4-00c04fd430c8"
        
        // Bundle Identifier 기반 UUID 생성
        return generateUUID(namespace: dnsNamespace, name: "\(bundleIdentifier).l2cap.service")
    }()
    
    /// L2CAP 특성 UUID (Bundle Identifier 기반으로 자동 생성)
    static let l2capCharacteristicUUID: CBUUID = {
        // Bundle Identifier 가져오기
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.default.app"
        
        // DNS 네임스페이스 UUID (RFC 4122 표준)
        let dnsNamespace = "6ba7b810-9dad-11d1-80b4-00c04fd430c8"
        
        // Bundle Identifier 기반 UUID 생성
        return generateUUID(namespace: dnsNamespace, name: "\(bundleIdentifier).l2cap.characteristic")
    }()
    
    /// 최대 전송 단위 (MTU)
    static let maxTransferUnit = 1024
    
    /// 하트비트 간격 (초)
    static let heartbeatInterval: TimeInterval = 30.0
    
    /// 연결 타임아웃 (초)
    static let connectionTimeout: TimeInterval = 10.0
    
    /// 재연결 시도 횟수
    static let maxReconnectAttempts = 3
}

// MARK: - Data Extension for SHA-1
private extension Data {
    /// SHA-1 해시 생성
    func sha1Hash() -> Data {
        var hash = [UInt8](repeating: 0, count: 20)
        self.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            CC_SHA1(baseAddress, CC_LONG(self.count), &hash)
        }
        return Data(hash)
    }
}
