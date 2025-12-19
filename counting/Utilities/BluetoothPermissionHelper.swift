//
//  BluetoothPermissionHelper.swift
//  counting
//
//  Created by MARKLIM on 2025-12-19.
//
//  블루투스 권한 관리 유틸리티
//

import Foundation
import CoreBluetooth

/// 블루투스 권한 상태
enum BluetoothPermissionStatus {
    case notDetermined      // 아직 권한 요청 안 함
    case authorized         // 권한 허용됨
    case denied             // 권한 거부됨
    case restricted         // 제한됨 (부모 제어 등)
    case unsupported        // 기기가 블루투스 미지원
    case poweredOff         // 블루투스 꺼짐
}

/// 블루투스 권한 관리 헬퍼
class BluetoothPermissionHelper: NSObject, ObservableObject {
    
    static let shared = BluetoothPermissionHelper()
    
    @Published var permissionStatus: BluetoothPermissionStatus = .notDetermined
    
    private var centralManager: CBCentralManager?
    private var permissionCheckCompletion: ((BluetoothPermissionStatus) -> Void)?
    
    private override init() {
        super.init()
    }
    
    /// 블루투스 권한 확인
    func checkPermission(completion: @escaping (BluetoothPermissionStatus) -> Void) {
        permissionCheckCompletion = completion
        
        // CBCentralManager 생성 시 자동으로 권한 요청
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        } else {
            // 이미 생성되어 있으면 현재 상태 반환
            let status = getCurrentStatus()
            completion(status)
        }
    }
    
    /// 현재 블루투스 상태 가져오기
    func getCurrentStatus() -> BluetoothPermissionStatus {
        guard let manager = centralManager else {
            return .notDetermined
        }
        
        switch manager.state {
        case .poweredOn:
            return .authorized
        case .poweredOff:
            return .poweredOff
        case .unauthorized:
            return .denied
        case .unsupported:
            return .unsupported
        case .resetting:
            return .notDetermined
        case .unknown:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }
    
    /// 설정 앱으로 이동
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothPermissionHelper: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let status = getCurrentStatus()
        
        DispatchQueue.main.async {
            self.permissionStatus = status
            self.permissionCheckCompletion?(status)
            self.permissionCheckCompletion = nil
        }
    }
}
