# 📘 L2CAP 블루투스 통신 완벽 가이드

> **학습 목적**: iOS Core Bluetooth 프레임워크를 사용한 L2CAP(Logical Link Control and Adaptation Protocol) 구현에 대한 심층 이해

---

## 📑 목차

1. [L2CAP이란?](#1-l2cap이란)
2. [왜 L2CAP을 사용하는가?](#2-왜-l2cap을-사용하는가)
3. [Core Bluetooth 아키텍처](#3-core-bluetooth-아키텍처)
4. [구현 파일 구조](#4-구현-파일-구조)
5. [핵심 개념 상세 설명](#5-핵심-개념-상세-설명)
6. [코드 분석](#6-코드-분석)
7. [실전 사용 시나리오](#7-실전-사용-시나리오)
8. [성능 최적화](#8-성능-최적화)
9. [디버깅 가이드](#9-디버깅-가이드)
10. [참고 자료](#10-참고-자료)

---

## 1. L2CAP이란?

### 1.1 정의

**L2CAP (Logical Link Control and Adaptation Protocol)**은 블루투스 프로토콜 스택의 핵심 계층으로, 상위 프로토콜과 하위 링크 계층 사이의 데이터 전송을 담당합니다.

```
┌─────────────────────────────┐
│   Application Layer         │  ← 우리가 작성하는 앱 코드
├─────────────────────────────┤
│   L2CAP Layer              │  ← 데이터 패킷화, 재조립
├─────────────────────────────┤
│   HCI (Host Controller)    │  ← 블루투스 칩과 통신
├─────────────────────────────┤
│   Physical Layer           │  ← 실제 무선 통신
└─────────────────────────────┘
```

### 1.2 주요 역할

1. **데이터 분할 및 재조립**: 큰 데이터를 작은 패킷으로 분할하고 수신 측에서 재조립
2. **멀티플렉싱**: 여러 상위 프로토콜이 동시에 사용 가능
3. **QoS (Quality of Service)**: 데이터 전송 품질 보장
4. **채널 관리**: 논리적 채널 생성 및 관리

---

## 2. 왜 L2CAP을 사용하는가?

### 2.1 GATT vs L2CAP 비교

| 특성 | GATT | L2CAP |
|------|------|-------|
| **전송 속도** | 느림 (20-512 bytes/packet) | 빠름 (최대 65535 bytes/packet) |
| **오버헤드** | 높음 (ATT 프로토콜 래핑) | 낮음 (직접 스트림) |
| **사용 난이도** | 쉬움 | 중간 |
| **적합한 용도** | 작은 데이터, 센서 값 | 대용량 데이터, 파일 전송 |
| **연결 방식** | Characteristic 기반 | 채널 기반 |

### 2.2 L2CAP의 장점

✅ **고속 전송**: GATT보다 5-10배 빠른 전송 속도  
✅ **스트림 기반**: InputStream/OutputStream으로 직관적 사용  
✅ **대용량 데이터**: 파일, 이미지, 동영상 전송에 적합  
✅ **낮은 레이턴시**: 프로토콜 오버헤드 최소화  

### 2.3 우리 프로젝트에서의 사용 목적

```swift
// 📍 위치: counting/Services/L2CAPManager.swift (1-10줄)
// 카운팅 앱의 카테고리 데이터를 빠르게 동기화하기 위해 L2CAP 사용
// GATT로는 여러 카테고리와 카운터를 전송할 때 느림
```

---

## 3. Core Bluetooth 아키텍처

### 3.1 Central-Peripheral 모델

```
┌─────────────────┐           ┌─────────────────┐
│   Central       │           │   Peripheral    │
│  (클라이언트)    │◄─────────►│    (서버)       │
│                 │  연결 요청  │                 │
│  - 스캔         │           │  - 광고         │
│  - 연결         │           │  - 대기         │
│  - 데이터 요청  │           │  - 응답         │
└─────────────────┘           └─────────────────┘
```

### 3.2 우리 구현의 역할

| 모드 | 역할 | 구현 위치 |
|------|------|----------|
| **Central** | 다른 기기 검색 및 연결 | `L2CAPManager.swift` (67-97줄) |
| **Peripheral** | 연결 대기 및 수락 | `L2CAPManager.swift` (99-113줄) |

---

## 4. 구현 파일 구조

### 4.1 전체 구조

```
counting/
├── Services/
│   └── L2CAPManager.swift              # 🔴 핵심 통신 로직
│
├── Models/
│   └── L2CAPDataModel.swift            # 🟡 데이터 구조 정의
│
├── Utilities/
│   └── BluetoothPermissionHelper.swift # 🟢 권한 관리
│
└── Views/
    └── Settings/
        └── BluetoothDeviceListView.swift # 🔵 사용자 인터페이스
```

### 4.2 각 파일의 역할

#### 🔴 L2CAPManager.swift (Services/)
**역할**: L2CAP 통신의 모든 핵심 로직 담당

**주요 클래스/구조체**:
- `L2CAPManager` (40-218줄): Singleton 매니저
- `CBCentralManagerDelegate` (220-268줄): Central 모드 델리게이트
- `CBPeripheralDelegate` (270-332줄): Peripheral 검색 델리게이트
- `CBPeripheralManagerDelegate` (334-397줄): Peripheral 모드 델리게이트
- `StreamDelegate` (399-426줄): 스트림 이벤트 처리

**핵심 메서드**:
```swift
// 📍 67-76줄: 주변 기기 스캔
func startScanning()

// 📍 85-92줄: 기기 연결
func connect(to peripheral: CBPeripheral)

// 📍 101-132줄: 데이터 전송
func send(data: Data)

// 📍 135-144줄: Peripheral 모드 시작
func startAdvertising()
```

---

#### 🟡 L2CAPDataModel.swift (Models/)
**역할**: 메시지 프로토콜 및 데이터 모델 정의

**주요 구조체**:
```swift
// 📍 14-18줄: 메시지 타입 열거형
enum L2CAPMessageType: UInt8, Codable {
    case sync = 0x01        // 데이터 동기화
    case request = 0x02     // 요청
    case response = 0x03    // 응답
    case heartbeat = 0x04   // 연결 유지
    case error = 0xFF       // 에러
}

// 📍 20-24줄: 메시지 프로토콜
protocol L2CAPMessage: Codable {
    var type: L2CAPMessageType { get }
    var timestamp: Date { get }
}

// 📍 26-34줄: 동기화 메시지
struct L2CAPSyncMessage: L2CAPMessage {
    let categories: [TallyCategory]  // 카운팅 데이터
}

// 📍 95-111줄: 메시지 인코더/디코더
class L2CAPMessageCoder {
    static func encode<T: L2CAPMessage>(_ message: T) throws -> Data
    static func decode(_ data: Data) throws -> any L2CAPMessage
}
```

**사용 예시**:
```swift
// 📍 실제 사용 위치: L2CAPManager.swift의 send() 메서드에서 사용
let syncMessage = L2CAPSyncMessage(categories: myCategories)
let data = try L2CAPMessageCoder.encode(syncMessage)
L2CAPManager.shared.send(data: data)
```

---

#### 🟢 BluetoothPermissionHelper.swift (Utilities/)
**역할**: iOS 블루투스 권한 관리

**주요 기능**:
```swift
// 📍 12-19줄: 권한 상태 정의
enum BluetoothPermissionStatus {
    case notDetermined  // 아직 요청 안 함
    case authorized     // 허용됨
    case denied         // 거부됨
    case restricted     // 제한됨
    case unsupported    // 미지원
    case poweredOff     // 꺼짐
}

// 📍 35-46줄: 권한 확인
func checkPermission(completion: @escaping (BluetoothPermissionStatus) -> Void)

// 📍 48-68줄: 현재 상태 가져오기
func getCurrentStatus() -> BluetoothPermissionStatus
```

**iOS 권한 시스템 이해**:
```
사용자가 앱 최초 실행
    ↓
CBCentralManager 생성 시 자동으로 권한 요청 팝업 표시
    ↓
사용자 선택: 허용 / 거부
    ↓
centralManagerDidUpdateState 델리게이트 호출
    ↓
권한 상태 저장 및 UI 업데이트
```

---

#### 🔵 BluetoothDeviceListView.swift (Views/Settings/)
**역할**: 블루투스 기기 검색 및 연결 UI

**주요 컴포넌트**:
```swift
// 📍 15-24줄: 뷰 상태 관리
@ObservedObject var l2capManager = L2CAPManager.shared
@ObservedObject var permissionHelper = BluetoothPermissionHelper.shared
@State private var showPermissionAlert = false
@State private var isScanning = false

// 📍 42-51줄: 연결 상태 헤더
private var connectionStatusHeader: some View

// 📍 53-75줄: 기기 목록
private var deviceList: some View

// 📍 77-91줄: 빈 상태 뷰
private var emptyStateView: some View
```

**UI 흐름**:
```
1. 뷰 표시 (.onAppear)
    ↓
2. 권한 확인 (checkPermissionAndScan)
    ↓
3. 스캔 시작 (startScanning)
    ↓
4. 기기 발견 시 목록에 추가
    ↓
5. 사용자가 기기 선택
    ↓
6. 연결 시도 (connectToDevice)
```

---

## 5. 핵심 개념 상세 설명

### 5.1 PSM (Protocol/Service Multiplexer)

**정의**: L2CAP 채널을 식별하는 고유 번호 (포트 번호와 유사)

```swift
// 📍 위치: L2CAPManager.swift (49줄)
private var publishedL2CAPChannel: CBL2CAPPSM = 0

// PSM은 Peripheral이 채널을 발행할 때 iOS가 자동으로 할당
// Central은 이 PSM 값을 읽어서 채널에 연결
```

**PSM 교환 과정**:
```
Peripheral                          Central
    │                                  │
    │ 1. publishL2CAPChannel()         │
    │    → iOS가 PSM 할당 (예: 128)    │
    │                                  │
    │ 2. PSM을 Characteristic에 저장   │
    │                                  │
    │ ◄────── 3. Characteristic 읽기 ─┤
    │                                  │
    │ ────── 4. PSM 값 전송 (128) ────►│
    │                                  │
    │ ◄──── 5. openL2CAPChannel(128) ─┤
    │                                  │
    │ ────── 6. 채널 연결 완료 ───────►│
```

**코드 위치**:
```swift
// 📍 Peripheral: L2CAPManager.swift (358-382줄)
func peripheralManager(_ peripheral: CBPeripheralManager, 
                      didPublishL2CAPChannel PSM: CBL2CAPPSM, 
                      error: Error?) {
    // PSM을 Characteristic에 저장
    let psmData = withUnsafeBytes(of: PSM.bigEndian) { Data($0) }
    let characteristic = CBMutableCharacteristic(
        type: l2capCharacteristicUUID,
        properties: [.read],
        value: psmData,
        permissions: [.readable]
    )
}

// 📍 Central: L2CAPManager.swift (305-314줄)
func peripheral(_ peripheral: CBPeripheral, 
               didUpdateValueFor characteristic: CBCharacteristic, 
               error: Error?) {
    // PSM 값 읽기
    let psm = data.withUnsafeBytes { $0.load(as: UInt16.self) }
    openL2CAPChannel(for: peripheral, psm: CBL2CAPPSM(psm))
}
```

---

### 5.2 스트림 (Stream) 기반 통신

**개념**: L2CAP은 InputStream과 OutputStream을 제공하여 파일 I/O처럼 데이터를 읽고 씁니다.

```swift
// 📍 위치: L2CAPManager.swift (316-332줄)
func peripheral(_ peripheral: CBPeripheral, 
               didOpen channel: CBL2CAPChannel?, 
               error: Error?) {
    // 입력 스트림 설정 (데이터 수신용)
    if let inputStream = channel.inputStream {
        inputStream.delegate = self
        inputStream.schedule(in: .main, forMode: .default)
        inputStream.open()
    }
    
    // 출력 스트림 설정 (데이터 전송용)
    if let outputStream = channel.outputStream {
        outputStream.delegate = self
        outputStream.schedule(in: .main, forMode: .default)
        outputStream.open()
    }
}
```

**스트림 이벤트 처리**:
```swift
// 📍 위치: L2CAPManager.swift (399-426줄)
func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
    switch eventCode {
    case .hasBytesAvailable:
        // 읽을 데이터가 있음
        if let inputStream = aStream as? InputStream {
            readData(from: inputStream)
        }
        
    case .hasSpaceAvailable:
        // 쓸 공간이 있음 (전송 가능)
        
    case .openCompleted:
        // 스트림 열림
        
    case .endEncountered:
        // 스트림 종료
        
    case .errorOccurred:
        // 에러 발생
    }
}
```

---

### 5.3 데이터 전송 프로토콜

**문제**: 스트림은 경계가 없어서 어디서 메시지가 끝나는지 알 수 없음

**해결책**: 길이 헤더 추가

```swift
// 📍 위치: L2CAPManager.swift (101-132줄)
func send(data: Data) {
    // 1단계: 데이터 길이를 4바이트로 전송
    var length = UInt32(data.count).bigEndian
    let lengthData = Data(bytes: &length, count: 4)
    outputStream.write(lengthData)
    
    // 2단계: 실제 데이터 전송
    outputStream.write(data)
}
```

**전송 포맷**:
```
┌──────────────┬────────────────────────┐
│ 길이 (4바이트) │  실제 데이터 (N바이트)   │
├──────────────┼────────────────────────┤
│   0x00000100  │  { "type": "sync", ... }│
└──────────────┴────────────────────────┘
     256바이트         256바이트 데이터
```

**수신 측 처리**:
```swift
// 📍 위치: L2CAPManager.swift (151-167줄)
private func readData(from inputStream: InputStream) {
    // 1단계: 길이 읽기 (4바이트)
    var lengthBuffer = [UInt8](repeating: 0, count: 4)
    inputStream.read(&lengthBuffer, maxLength: 4)
    let length = UInt32(bigEndian: ...)
    
    // 2단계: 실제 데이터 읽기 (length 바이트)
    var dataBuffer = [UInt8](repeating: 0, count: Int(length))
    inputStream.read(&dataBuffer, maxLength: Int(length))
    
    // 3단계: 데이터 처리
    let data = Data(bytes: dataBuffer, count: Int(length))
    onDataReceived?(data)
}
```

---

### 5.4 서비스 및 특성 (Service & Characteristic)

**개념**: L2CAP 채널을 열기 전에 GATT를 사용하여 PSM을 교환합니다.

```swift
// 📍 위치: L2CAPManager.swift (52-54줄)
private let serviceUUID = CBUUID(string: "00000000-0000-1000-8000-00805F9B34FB")
private let l2capCharacteristicUUID = CBUUID(string: "00000001-0000-1000-8000-00805F9B34FB")
```

**GATT 구조**:
```
Service (서비스)
└── Characteristic (특성)
    ├── Properties: [.read]
    ├── Permissions: [.readable]
    └── Value: PSM 값 (2바이트)
```

**검색 과정**:
```swift
// 📍 위치: L2CAPManager.swift (270-292줄)

// 1단계: 서비스 검색
func peripheral(_ peripheral: CBPeripheral, didConnect ...) {
    peripheral.discoverServices([serviceUUID])
}

// 2단계: 특성 검색
func peripheral(_ peripheral: CBPeripheral, didDiscoverServices ...) {
    peripheral.discoverCharacteristics([l2capCharacteristicUUID], for: service)
}

// 3단계: 특성 값 읽기
func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristics ...) {
    peripheral.readValue(for: characteristic)
}

// 4단계: PSM 값 획득
func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic ...) {
    let psm = characteristic.value  // PSM 값
    openL2CAPChannel(for: peripheral, psm: psm)
}
```

---

## 6. 코드 분석

### 6.1 Central 모드 전체 흐름

```swift
// ═══════════════════════════════════════════════════════════
// 1단계: 스캔 시작
// 📍 위치: L2CAPManager.swift (67-76줄)
// ═══════════════════════════════════════════════════════════
func startScanning() {
    guard centralManager.state == .poweredOn else {
        connectionState = .error("Bluetooth is not powered on")
        return
    }
    
    discoveredDevices.removeAll()
    connectionState = .scanning
    // serviceUUID를 가진 기기만 검색
    centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
}

// ═══════════════════════════════════════════════════════════
// 2단계: 기기 발견 (델리게이트 자동 호출)
// 📍 위치: L2CAPManager.swift (235-245줄)
// ═══════════════════════════════════════════════════════════
func centralManager(_ central: CBCentralManager, 
                   didDiscover peripheral: CBPeripheral, 
                   advertisementData: [String : Any], 
                   rssi RSSI: NSNumber) {
    // 중복 체크 후 목록에 추가
    if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
        DispatchQueue.main.async {
            self.discoveredDevices.append(peripheral)
        }
    }
}

// ═══════════════════════════════════════════════════════════
// 3단계: 연결 시도
// 📍 위치: L2CAPManager.swift (85-92줄)
// ═══════════════════════════════════════════════════════════
func connect(to peripheral: CBPeripheral) {
    stopScanning()
    connectionState = .connecting
    connectedPeripheral = peripheral
    peripheral.delegate = self  // 중요: 델리게이트 설정
    centralManager.connect(peripheral, options: nil)
}

// ═══════════════════════════════════════════════════════════
// 4단계: 연결 성공 (델리게이트 자동 호출)
// 📍 위치: L2CAPManager.swift (247-261줄)
// ═══════════════════════════════════════════════════════════
func centralManager(_ central: CBCentralManager, 
                   didConnect peripheral: CBPeripheral) {
    connectionState = .connected
    connectedDevices.append(peripheral)
    
    // 서비스 검색 시작
    peripheral.discoverServices([serviceUUID])
}

// ═══════════════════════════════════════════════════════════
// 5단계: 서비스 발견 (델리게이트 자동 호출)
// 📍 위치: L2CAPManager.swift (276-286줄)
// ═══════════════════════════════════════════════════════════
func peripheral(_ peripheral: CBPeripheral, 
               didDiscoverServices error: Error?) {
    guard let services = peripheral.services else { return }
    
    for service in services {
        // L2CAP PSM을 담고 있는 특성 검색
        peripheral.discoverCharacteristics([l2capCharacteristicUUID], for: service)
    }
}

// ═══════════════════════════════════════════════════════════
// 6단계: 특성 발견 (델리게이트 자동 호출)
// 📍 위치: L2CAPManager.swift (288-302줄)
// ═══════════════════════════════════════════════════════════
func peripheral(_ peripheral: CBPeripheral, 
               didDiscoverCharacteristicsFor service: CBService, 
               error: Error?) {
    guard let characteristics = service.characteristics else { return }
    
    for characteristic in characteristics {
        if characteristic.uuid == l2capCharacteristicUUID {
            // PSM 값 읽기 요청
            peripheral.readValue(for: characteristic)
        }
    }
}

// ═══════════════════════════════════════════════════════════
// 7단계: PSM 값 획득 (델리게이트 자동 호출)
// 📍 위치: L2CAPManager.swift (304-315줄)
// ═══════════════════════════════════════════════════════════
func peripheral(_ peripheral: CBPeripheral, 
               didUpdateValueFor characteristic: CBCharacteristic, 
               error: Error?) {
    guard let data = characteristic.value else { return }
    
    // PSM 값 추출 (2바이트)
    if data.count >= 2 {
        let psm = data.withUnsafeBytes { $0.load(as: UInt16.self) }
        // L2CAP 채널 열기
        openL2CAPChannel(for: peripheral, psm: CBL2CAPPSM(psm))
    }
}

// ═══════════════════════════════════════════════════════════
// 8단계: L2CAP 채널 열기
// 📍 위치: L2CAPManager.swift (148-149줄)
// ═══════════════════════════════════════════════════════════
private func openL2CAPChannel(for peripheral: CBPeripheral, psm: CBL2CAPPSM) {
    peripheral.openL2CAPChannel(psm)
}

// ═══════════════════════════════════════════════════════════
// 9단계: 채널 열림 (델리게이트 자동 호출)
// 📍 위치: L2CAPManager.swift (317-333줄)
// ═══════════════════════════════════════════════════════════
func peripheral(_ peripheral: CBPeripheral, 
               didOpen channel: CBL2CAPChannel?, 
               error: Error?) {
    guard let channel = channel else { return }
    
    l2capChannel = channel
    
    // 입력 스트림 설정 (데이터 수신)
    if let inputStream = channel.inputStream {
        inputStream.delegate = self
        inputStream.schedule(in: .main, forMode: .default)
        inputStream.open()
    }
    
    // 출력 스트림 설정 (데이터 전송)
    if let outputStream = channel.outputStream {
        outputStream.delegate = self
        outputStream.schedule(in: .main, forMode: .default)
        outputStream.open()
    }
}

// ═══════════════════════════════════════════════════════════
// 10단계: 데이터 전송 준비 완료!
// 이제 send(data:) 메서드로 데이터 전송 가능
// ═══════════════════════════════════════════════════════════
```

---

### 6.2 Peripheral 모드 전체 흐름

```swift
// ═══════════════════════════════════════════════════════════
// 1단계: 광고 시작
// 📍 위치: L2CAPManager.swift (135-144줄)
// ═══════════════════════════════════════════════════════════
func startAdvertising() {
    guard peripheralManager.state == .poweredOn else {
        connectionState = .error("Bluetooth is not powered on")
        return
    }
    
    // L2CAP 채널 발행 (iOS가 자동으로 PSM 할당)
    peripheralManager.publishL2CAPChannel(withEncryption: true)
}

// ═══════════════════════════════════════════════════════════
// 2단계: PSM 할당됨 (델리게이트 자동 호출)
// 📍 위치: L2CAPManager.swift (358-382줄)
// ═══════════════════════════════════════════════════════════
func peripheralManager(_ peripheral: CBPeripheralManager, 
                      didPublishL2CAPChannel PSM: CBL2CAPPSM, 
                      error: Error?) {
    publishedL2CAPChannel = PSM
    
    // PSM을 Characteristic에 저장
    let psmData = withUnsafeBytes(of: PSM.bigEndian) { Data($0) }
    let characteristic = CBMutableCharacteristic(
        type: l2capCharacteristicUUID,
        properties: [.read],
        value: psmData,
        permissions: [.readable]
    )
    
    // 서비스 생성 및 등록
    let service = CBMutableService(type: serviceUUID, primary: true)
    service.characteristics = [characteristic]
    peripheralManager.add(service)
    
    // 광고 시작
    peripheralManager.startAdvertising([
        CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
        CBAdvertisementDataLocalNameKey: "Counting App"
    ])
}

// ═══════════════════════════════════════════════════════════
// 3단계: Central이 연결 시도
// (Central 측에서 connect() 호출)
// ═══════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════
// 4단계: L2CAP 채널 열림 (델리게이트 자동 호출)
// 📍 위치: L2CAPManager.swift (397-418줄)
// ═══════════════════════════════════════════════════════════
func peripheralManager(_ peripheral: CBPeripheralManager, 
                      didOpen channel: CBL2CAPChannel?, 
                      error: Error?) {
    guard let channel = channel else { return }
    
    l2capChannel = channel
    
    // 스트림 설정 (Central과 동일)
    if let inputStream = channel.inputStream {
        inputStream.delegate = self
        inputStream.schedule(in: .main, forMode: .default)
        inputStream.open()
    }
    
    if let outputStream = channel.outputStream {
        outputStream.delegate = self
        outputStream.schedule(in: .main, forMode: .default)
        outputStream.open()
    }
}

// ═══════════════════════════════════════════════════════════
// 5단계: 데이터 송수신 준비 완료!
// ═══════════════════════════════════════════════════════════
```

---

### 6.3 데이터 송수신 상세

#### 전송 (Send)

```swift
// ═══════════════════════════════════════════════════════════
// 📍 위치: L2CAPManager.swift (101-132줄)
// ═══════════════════════════════════════════════════════════
func send(data: Data) {
    guard let channel = l2capChannel else {
        print("❌ L2CAP channel is not open")
        return
    }
    
    guard let outputStream = channel.outputStream else {
        print("❌ Output stream is not available")
        return
    }
    
    // ───────────────────────────────────────────────────────
    // 1단계: 데이터 길이 전송 (4바이트)
    // ───────────────────────────────────────────────────────
    var length = UInt32(data.count).bigEndian  // 네트워크 바이트 순서
    let lengthData = Data(bytes: &length, count: 4)
    
    lengthData.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
        if let baseAddress = bytes.baseAddress?.assumingMemoryBound(to: UInt8.self) {
            outputStream.write(baseAddress, maxLength: 4)
        }
    }
    
    // ───────────────────────────────────────────────────────
    // 2단계: 실제 데이터 전송
    // ───────────────────────────────────────────────────────
    data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
        if let baseAddress = bytes.baseAddress?.assumingMemoryBound(to: UInt8.self) {
            let written = outputStream.write(baseAddress, maxLength: data.count)
            if written == data.count {
                print("✅ Successfully sent \(written) bytes via L2CAP")
            } else {
                print("⚠️ Partial write: \(written)/\(data.count) bytes")
            }
        }
    }
}
```

**전송 과정 시각화**:
```
메모리                     네트워크
┌────────────┐            ┌────────────┐
│ Data 객체   │            │ 바이트 스트림│
│ (Swift)    │  ────────► │ (Bluetooth)│
└────────────┘            └────────────┘
     │                          │
     │ withUnsafeBytes          │
     ↓                          ↓
┌────────────┐            ┌────────────┐
│ UInt8 배열  │  write()   │ 물리적 전송 │
│ [0x01, ... │  ────────► │            │
└────────────┘            └────────────┘
```

---

#### 수신 (Receive)

```swift
// ═══════════════════════════════════════════════════════════
// 📍 위치: L2CAPManager.swift (151-167줄)
// ═══════════════════════════════════════════════════════════
private func readData(from inputStream: InputStream) {
    let bufferSize = 1024
    var buffer = [UInt8](repeating: 0, count: bufferSize)
    
    // ───────────────────────────────────────────────────────
    // 스트림에서 사용 가능한 모든 데이터 읽기
    // ───────────────────────────────────────────────────────
    while inputStream.hasBytesAvailable {
        let bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
        
        if bytesRead > 0 {
            let data = Data(bytes: buffer, count: bytesRead)
            
            // 메인 스레드에서 UI 업데이트
            DispatchQueue.main.async {
                self.receivedData = data
                self.onDataReceived?(data)  // 콜백 호출
            }
            
            print("✅ Received \(bytesRead) bytes via L2CAP")
        }
    }
}

// ═══════════════════════════════════════════════════════════
// 스트림 이벤트 처리
// 📍 위치: L2CAPManager.swift (420-426줄)
// ═══════════════════════════════════════════════════════════
func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
    switch eventCode {
    case .hasBytesAvailable:
        // 읽을 데이터가 있을 때 자동 호출
        if let inputStream = aStream as? InputStream {
            readData(from: inputStream)
        }
        
    case .hasSpaceAvailable:
        // 쓸 공간이 있을 때 (전송 가능)
        print("✅ Stream has space available for writing")
        
    case .openCompleted:
        print("✅ Stream opened")
        
    case .endEncountered:
        print("🔌 Stream end encountered")
        aStream.close()
        aStream.remove(from: .main, forMode: .default)
        
    case .errorOccurred:
        print("❌ Stream error occurred")
        aStream.close()
        aStream.remove(from: .main, forMode: .default)
        
    default:
        print("⚠️ Unknown stream event: \(eventCode)")
    }
}
```

**수신 과정 시각화**:
```
블루투스 칩              InputStream              앱 코드
┌──────────┐           ┌──────────┐           ┌──────────┐
│ 데이터 도착│  ──────► │ 버퍼 저장 │  ──────► │ 이벤트   │
└──────────┘           └──────────┘           │ 발생     │
                             │                └──────────┘
                             │ hasBytesAvailable         │
                             ↓                            ↓
                       ┌──────────┐           ┌──────────┐
                       │ read()   │  ──────► │ 데이터    │
                       │ 호출     │           │ 처리     │
                       └──────────┘           └──────────┘
```

---

### 6.4 메시지 인코딩/디코딩

```swift
// ═══════════════════════════════════════════════════════════
// 인코딩 (Swift 객체 → JSON → Data)
// 📍 위치: L2CAPDataModel.swift (98-102줄)
// ═══════════════════════════════════════════════════════════
static func encode<T: L2CAPMessage>(_ message: T) throws -> Data {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601  // 날짜 형식 통일
    return try encoder.encode(message)
}

// 사용 예시:
let syncMessage = L2CAPSyncMessage(categories: myCategories)
let data = try L2CAPMessageCoder.encode(syncMessage)
// data = {"type":1,"timestamp":"2025-12-19T22:00:00Z","categories":[...]}
```

```swift
// ═══════════════════════════════════════════════════════════
// 디코딩 (Data → JSON → Swift 객체)
// 📍 위치: L2CAPDataModel.swift (104-127줄)
// ═══════════════════════════════════════════════════════════
static func decode(_ data: Data) throws -> any L2CAPMessage {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    
    // ───────────────────────────────────────────────────────
    // 1단계: 메시지 타입만 먼저 확인
    // ───────────────────────────────────────────────────────
    struct MessageTypeWrapper: Codable {
        let type: L2CAPMessageType
    }
    
    let wrapper = try decoder.decode(MessageTypeWrapper.self, from: data)
    
    // ───────────────────────────────────────────────────────
    // 2단계: 타입에 따라 적절한 구조체로 디코딩
    // ───────────────────────────────────────────────────────
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

// 사용 예시:
L2CAPManager.shared.onDataReceived = { data in
    if let message = try? L2CAPMessageCoder.decode(data) {
        switch message {
        case let syncMsg as L2CAPSyncMessage:
            print("Received \(syncMsg.categories.count) categories")
        default:
            break
        }
    }
}
```

---

## 7. 실전 사용 시나리오

### 7.1 시나리오 1: 두 기기 간 카운팅 데이터 동기화

**상황**: 사용자가 두 대의 iPhone을 가지고 있고, 카운팅 데이터를 공유하고 싶음

#### 기기 A (Peripheral - 데이터 제공자)

```swift
// ═══════════════════════════════════════════════════════════
// 1. 광고 시작
// ═══════════════════════════════════════════════════════════
L2CAPManager.shared.startAdvertising()

// ═══════════════════════════════════════════════════════════
// 2. 데이터 수신 대기
// ═══════════════════════════════════════════════════════════
L2CAPManager.shared.onDataReceived = { data in
    if let message = try? L2CAPMessageCoder.decode(data) {
        switch message {
        case let requestMsg as L2CAPRequestMessage:
            // 요청 받음: 전체 데이터 전송
            if requestMsg.requestType == .fullSync {
                let syncMessage = L2CAPSyncMessage(
                    categories: TallyStore.shared.categories
                )
                if let responseData = try? L2CAPMessageCoder.encode(syncMessage) {
                    L2CAPManager.shared.send(data: responseData)
                }
            }
        default:
            break
        }
    }
}
```

#### 기기 B (Central - 데이터 요청자)

```swift
// ═══════════════════════════════════════════════════════════
// 1. UI에서 블루투스 기기 목록 표시
// ═══════════════════════════════════════════════════════════
struct SettingsView: View {
    @State private var showBluetoothDevices = false
    
    var body: some View {
        Button("Sync with Another Device") {
            showBluetoothDevices = true
        }
        .sheet(isPresented: $showBluetoothDevices) {
            BluetoothDeviceListView()
        }
    }
}

// ═══════════════════════════════════════════════════════════
// 2. 연결 성공 후 데이터 요청
// ═══════════════════════════════════════════════════════════
// BluetoothDeviceListView에서 기기 선택 시:
L2CAPManager.shared.connect(to: selectedDevice)

// 연결 상태 감지
L2CAPManager.shared.$connectionState
    .sink { state in
        if case .connected = state {
            // 연결 성공! 데이터 요청
            let requestMessage = L2CAPRequestMessage(requestType: .fullSync)
            if let data = try? L2CAPMessageCoder.encode(requestMessage) {
                L2CAPManager.shared.send(data: data)
            }
        }
    }

// ═══════════════════════════════════════════════════════════
// 3. 데이터 수신 및 병합
// ═══════════════════════════════════════════════════════════
L2CAPManager.shared.onDataReceived = { data in
    if let message = try? L2CAPMessageCoder.decode(data) {
        switch message {
        case let syncMsg as L2CAPSyncMessage:
            // 받은 카테고리 데이터 병합
            DispatchQueue.main.async {
                for category in syncMsg.categories {
                    // 중복 체크 후 추가
                    if !TallyStore.shared.categories.contains(where: { $0.id == category.id }) {
                        TallyStore.shared.categories.append(category)
                    }
                }
                
                // 성공 응답 전송
                let response = L2CAPResponseMessage(success: true, message: "Sync completed")
                if let responseData = try? L2CAPMessageCoder.encode(response) {
                    L2CAPManager.shared.send(data: responseData)
                }
            }
        default:
            break
        }
    }
}
```

---

### 7.2 시나리오 2: 실시간 카운터 증가 동기화

**상황**: 두 기기에서 동시에 카운터를 조작하고 실시간으로 동기화

```swift
// ═══════════════════════════════════════════════════════════
// 카운터 증가 시 자동 전송
// 📍 위치: Models.swift의 TallyStore.updateCount() 메서드에 추가
// ═══════════════════════════════════════════════════════════
func updateCount(categoryId: UUID, counterId: UUID, delta: Double) {
    // 기존 로직...
    categories[catIndex].counters[counterIndex].count += delta
    
    // L2CAP으로 변경 사항 전송
    if L2CAPManager.shared.connectionState == .connected {
        let syncMessage = L2CAPSyncMessage(categories: categories)
        if let data = try? L2CAPMessageCoder.encode(syncMessage) {
            L2CAPManager.shared.send(data: data)
        }
    }
}

// ═══════════════════════════════════════════════════════════
// 수신 측: 자동 업데이트
// ═══════════════════════════════════════════════════════════
L2CAPManager.shared.onDataReceived = { data in
    if let message = try? L2CAPMessageCoder.decode(data) {
        switch message {
        case let syncMsg as L2CAPSyncMessage:
            DispatchQueue.main.async {
                // 타임스탬프 비교하여 최신 데이터만 적용
                for receivedCategory in syncMsg.categories {
                    if let index = TallyStore.shared.categories.firstIndex(where: { $0.id == receivedCategory.id }) {
                        // 기존 카테고리 업데이트
                        TallyStore.shared.categories[index] = receivedCategory
                    } else {
                        // 새 카테고리 추가
                        TallyStore.shared.categories.append(receivedCategory)
                    }
                }
            }
        default:
            break
        }
    }
}
```

---

### 7.3 시나리오 3: 연결 유지 (Heartbeat)

**상황**: 장시간 연결 유지를 위해 주기적으로 heartbeat 전송

```swift
// ═══════════════════════════════════════════════════════════
// Heartbeat 타이머 설정
// 📍 위치: L2CAPManager.swift에 추가
// ═══════════════════════════════════════════════════════════
private var heartbeatTimer: Timer?

func startHeartbeat() {
    heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
        let heartbeat = L2CAPHeartbeatMessage()
        if let data = try? L2CAPMessageCoder.encode(heartbeat) {
            self?.send(data: data)
        }
    }
}

func stopHeartbeat() {
    heartbeatTimer?.invalidate()
    heartbeatTimer = nil
}

// 연결 시 시작
func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
    // ... 기존 코드 ...
    startHeartbeat()
}

// 연결 해제 시 중지
func disconnect() {
    stopHeartbeat()
    // ... 기존 코드 ...
}
```

---

## 8. 성능 최적화

### 8.1 전송 속도 최적화

```swift
// ═══════════════════════════════════════════════════════════
// 문제: 큰 데이터를 한 번에 전송하면 블로킹 발생
// 해결: 청크 단위로 분할 전송
// ═══════════════════════════════════════════════════════════
func sendLargeData(_ data: Data) {
    let chunkSize = 4096  // 4KB 청크
    var offset = 0
    
    while offset < data.count {
        let end = min(offset + chunkSize, data.count)
        let chunk = data[offset..<end]
        
        // 청크 전송
        chunk.withUnsafeBytes { bytes in
            if let baseAddress = bytes.baseAddress?.assumingMemoryBound(to: UInt8.self) {
                outputStream.write(baseAddress, maxLength: chunk.count)
            }
        }
        
        offset = end
        
        // CPU 양보 (다른 작업 처리 가능)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.001))
    }
}
```

### 8.2 메모리 최적화

```swift
// ═══════════════════════════════════════════════════════════
// 문제: 큰 데이터 수신 시 메모리 부족
// 해결: 스트리밍 방식으로 처리
// ═══════════════════════════════════════════════════════════
private var receivedBuffer = Data()
private var expectedLength: Int?

private func readDataStreaming(from inputStream: InputStream) {
    var buffer = [UInt8](repeating: 0, count: 1024)
    
    while inputStream.hasBytesAvailable {
        let bytesRead = inputStream.read(&buffer, maxLength: 1024)
        
        if bytesRead > 0 {
            receivedBuffer.append(contentsOf: buffer[0..<bytesRead])
            
            // 길이 헤더 읽기
            if expectedLength == nil && receivedBuffer.count >= 4 {
                expectedLength = Int(receivedBuffer.withUnsafeBytes { 
                    $0.load(as: UInt32.self).bigEndian 
                })
                receivedBuffer.removeFirst(4)
            }
            
            // 전체 데이터 수신 완료
            if let expected = expectedLength, receivedBuffer.count >= expected {
                let completeData = receivedBuffer.prefix(expected)
                onDataReceived?(Data(completeData))
                
                // 버퍼 정리
                receivedBuffer.removeFirst(expected)
                expectedLength = nil
            }
        }
    }
}
```

### 8.3 배터리 최적화

```swift
// ═══════════════════════════════════════════════════════════
// 스캔 시간 제한
// 📍 위치: BluetoothDeviceListView.swift (156-165줄)
// ═══════════════════════════════════════════════════════════
private func startScanning() {
    isScanning = true
    l2capManager.startScanning()
    
    // 30초 후 자동 중지 (배터리 절약)
    DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
        if isScanning {
            stopScanning()
        }
    }
}

// ═══════════════════════════════════════════════════════════
// 백그라운드에서 연결 해제
// ═══════════════════════════════════════════════════════════
@Environment(\.scenePhase) var scenePhase

.onChange(of: scenePhase) { oldPhase, newPhase in
    if newPhase == .background {
        // 백그라운드 진입 시 연결 해제 (선택사항)
        L2CAPManager.shared.disconnect()
    }
}
```

---

## 9. 디버깅 가이드

### 9.1 로그 분석

```swift
// ═══════════════════════════════════════════════════════════
// 전체 통신 과정 로그
// ═══════════════════════════════════════════════════════════

// Central 모드:
✅ Bluetooth is powered on
📡 Discovered device: iPhone (John)
✅ Connected to iPhone (John)
🔍 Discovered service: 00000000-0000-1000-8000-00805F9B34FB
🔍 Discovered characteristic: 00000001-0000-1000-8000-00805F9B34FB
📡 Received L2CAP PSM: 128
✅ L2CAP channel opened successfully
✅ Stream opened (input)
✅ Stream opened (output)
✅ Successfully sent 256 bytes via L2CAP
✅ Received 512 bytes via L2CAP

// Peripheral 모드:
✅ Peripheral Manager is powered on
✅ L2CAP channel published with PSM: 128
✅ L2CAP channel opened (peripheral mode)
✅ Stream opened (input)
✅ Stream opened (output)
✅ Received 256 bytes via L2CAP
✅ Successfully sent 512 bytes via L2CAP
```

### 9.2 일반적인 문제 해결

#### 문제 1: 기기가 검색되지 않음

```swift
// 체크리스트:
// 1. 블루투스 켜짐 확인
if centralManager.state != .poweredOn {
    print("❌ Bluetooth is not powered on")
}

// 2. 권한 확인
BluetoothPermissionHelper.shared.checkPermission { status in
    if status != .authorized {
        print("❌ Bluetooth permission denied")
    }
}

// 3. UUID 일치 확인
// Peripheral과 Central의 serviceUUID가 동일해야 함
print("Service UUID: \(serviceUUID)")

// 4. 광고 중인지 확인 (Peripheral)
if !peripheralManager.isAdvertising {
    print("❌ Not advertising")
}
```

#### 문제 2: 연결이 끊김

```swift
// 원인 분석:
func centralManager(_ central: CBCentralManager, 
                   didDisconnectPeripheral peripheral: CBPeripheral, 
                   error: Error?) {
    if let error = error {
        print("❌ Disconnection error: \(error.localizedDescription)")
        // 일반적인 원인:
        // - 거리 초과 (10m 이상)
        // - 배터리 절약 모드
        // - 블루투스 꺼짐
        // - 앱 종료
    }
}

// 재연결 시도:
func autoReconnect(to peripheral: CBPeripheral, maxAttempts: Int = 3) {
    var attempts = 0
    
    func tryConnect() {
        attempts += 1
        if attempts <= maxAttempts {
            print("🔄 Reconnection attempt \(attempts)/\(maxAttempts)")
            centralManager.connect(peripheral, options: nil)
            
            // 10초 후 재시도
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if connectionState != .connected {
                    tryConnect()
                }
            }
        } else {
            print("❌ Max reconnection attempts reached")
        }
    }
    
    tryConnect()
}
```

#### 문제 3: 데이터가 전송되지 않음

```swift
// 디버깅:
func send(data: Data) {
    // 1. 채널 확인
    guard let channel = l2capChannel else {
        print("❌ L2CAP channel is not open")
        return
    }
    
    // 2. 스트림 확인
    guard let outputStream = channel.outputStream else {
        print("❌ Output stream is not available")
        return
    }
    
    // 3. 스트림 상태 확인
    print("Stream status: \(outputStream.streamStatus.rawValue)")
    // 0: not open, 1: opening, 2: open, 3: reading, 4: writing, 5: at end, 6: closed, 7: error
    
    if outputStream.streamStatus != .open {
        print("❌ Stream is not open")
        return
    }
    
    // 4. 전송 시도
    let written = outputStream.write(...)
    print("Written: \(written) / \(data.count) bytes")
}
```

### 9.3 Xcode Instruments 프로파일링

```bash
# 블루투스 활동 모니터링
1. Xcode → Product → Profile (Cmd + I)
2. "Logging" 템플릿 선택
3. "os_log" 필터에 "bluetooth" 입력
4. 앱 실행 및 블루투스 작업 수행
5. 로그 분석
```

---

## 10. 참고 자료

### 10.1 Apple 공식 문서

1. **Core Bluetooth Programming Guide**
   - https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/

2. **CBL2CAPChannel**
   - https://developer.apple.com/documentation/corebluetooth/cbl2capchannel

3. **CBCentralManager**
   - https://developer.apple.com/documentation/corebluetooth/cbcentralmanager

4. **CBPeripheralManager**
   - https://developer.apple.com/documentation/corebluetooth/cbperipheralmanager

### 10.2 WWDC 세션

1. **WWDC 2019 - What's New in Core Bluetooth**
   - L2CAP 채널 소개
   - https://developer.apple.com/videos/play/wwdc2019/901/

2. **WWDC 2017 - What's New in Core Bluetooth**
   - 성능 최적화 팁
   - https://developer.apple.com/videos/play/wwdc2017/712/

### 10.3 추가 학습 자료

1. **Bluetooth SIG 공식 스펙**
   - L2CAP 프로토콜 상세 설명
   - https://www.bluetooth.com/specifications/specs/

2. **Ray Wenderlich - Core Bluetooth Tutorial**
   - 초보자 친화적 튜토리얼
   - https://www.raywenderlich.com/231-core-bluetooth-tutorial-for-ios-heart-rate-monitor

---

## 📝 학습 체크리스트

- [ ] L2CAP의 개념과 GATT와의 차이점 이해
- [ ] Central-Peripheral 모델 이해
- [ ] PSM 교환 과정 이해
- [ ] 스트림 기반 통신 방식 이해
- [ ] 데이터 인코딩/디코딩 구현 이해
- [ ] 권한 관리 시스템 이해
- [ ] 실제 프로젝트에 적용 가능

---

## 🎓 연습 과제

1. **기본**: 두 기기 간 간단한 텍스트 메시지 전송 구현
2. **중급**: 파일 전송 기능 추가 (진행률 표시 포함)
3. **고급**: 여러 기기 동시 연결 및 그룹 채팅 구현

---

**작성일**: 2025-12-19  
**버전**: 1.0  
**프로젝트**: Counting App for iOS
