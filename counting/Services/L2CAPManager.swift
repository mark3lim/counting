//
//  L2CAPManager.swift
//  counting
//
//  Created by MARKLIM on 2025-12-19.
//
//  L2CAP 블루투스 통신을 관리하는 매니저 클래스입니다.
//  Core Bluetooth를 사용하여 L2CAP 채널을 통한 양방향 데이터 전송을 지원합니다.
//

import Foundation
import CoreBluetooth
import Combine

/// L2CAP 연결 상태
enum L2CAPConnectionState: Equatable {
    case disconnected
    case scanning
    case connecting
    case connected
    case error(String)
}

/// L2CAP 통신 매니저
/// Singleton 패턴으로 구현되어 앱 전체에서 하나의 인스턴스만 사용합니다.
@MainActor
class L2CAPManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    static let shared = L2CAPManager()
    
    // MARK: - Published Properties
    @Published var connectionState: L2CAPConnectionState = .disconnected
    @Published var connectedDevices: [CBPeripheral] = []
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var receivedData: Data?
    
    // MARK: - Private Properties
    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!
    
    // L2CAP 채널
    private var l2capChannel: CBL2CAPChannel?
    private var publishedL2CAPChannel: CBL2CAPPSM = 0
    
    // 연결된 주변기기
    private var connectedPeripheral: CBPeripheral?
    
    
    // 서비스 및 특성 UUID (L2CAPConfiguration에서 자동 생성)
    private let serviceUUID = L2CAPConfiguration.serviceUUID
    private let l2capCharacteristicUUID = L2CAPConfiguration.l2capCharacteristicUUID

    
    // 데이터 수신 핸들러 (Sendable)
    var onDataReceived: (@Sendable (Data) -> Void)?
    
    // MARK: - Initialization
    private override init() {
        super.init()
        // CBCentralManager, CBPeripheralManager delegate queue nil -> main queue
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    
    /// 주변 기기 스캔 시작
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            connectionState = .error("Bluetooth is not powered on")
            return
        }
        
        discoveredDevices.removeAll()
        connectionState = .scanning
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
    }
    
    /// 스캔 중지
    func stopScanning() {
        centralManager.stopScan()
        if connectionState == .scanning {
            connectionState = .disconnected
        }
    }
    
    /// 특정 기기에 연결
    func connect(to peripheral: CBPeripheral) {
        stopScanning()
        connectionState = .connecting
        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    /// 연결 해제
    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        l2capChannel = nil
        connectedPeripheral = nil
        connectionState = .disconnected
    }
    
    /// L2CAP 채널을 통해 데이터 전송
    func send(data: Data) {
        guard let channel = l2capChannel else {
            print("❌ L2CAP channel is not open")
            return
        }
        
        guard let outputStream = channel.outputStream else {
            print("❌ Output stream is not available")
            return
        }
        
        // 데이터 길이를 먼저 전송 (4바이트)
        var length = UInt32(data.count).bigEndian
        let lengthData = Data(bytes: &length, count: 4)
        
        // 길이 전송
        lengthData.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            if let baseAddress = bytes.baseAddress?.assumingMemoryBound(to: UInt8.self) {
                outputStream.write(baseAddress, maxLength: 4)
            }
        }
        
        // 실제 데이터 전송
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
    
    /// Peripheral 모드로 L2CAP 서비스 시작
    func startAdvertising() {
        guard peripheralManager.state == .poweredOn else {
            connectionState = .error("Bluetooth is not powered on")
            return
        }
        
        // L2CAP 채널 발행
        peripheralManager.publishL2CAPChannel(withEncryption: true)
    }
    
    /// 광고 중지
    func stopAdvertising() {
        peripheralManager.stopAdvertising()
        if publishedL2CAPChannel != 0 {
            peripheralManager.unpublishL2CAPChannel(publishedL2CAPChannel)
            publishedL2CAPChannel = 0
        }
    }
    
    // MARK: - Private Methods
    
    /// L2CAP 채널 열기
    private func openL2CAPChannel(for peripheral: CBPeripheral, psm: CBL2CAPPSM) {
        peripheral.openL2CAPChannel(psm)
    }
    
    /// 스트림에서 데이터 읽기
    private func readData(from inputStream: InputStream) {
        let bufferSize = 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        
        while inputStream.hasBytesAvailable {
            let bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
            if bytesRead > 0 {
                let data = Data(bytes: buffer, count: bytesRead)
                // 이미 MainActor (StreamDelegate in .main)
                self.receivedData = data
                self.onDataReceived?(data)
                
                print("✅ Received \(bytesRead) bytes via L2CAP")
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate
// Delegate methods are called on Main Queue (queue: nil in init), so we can treat them as MainActor isolated implicitly
// or mark class as MainActor and ensure conformance.
// Since the whole class is @MainActor, these methods need to be compliant. 
// CBCentralManagerDelegate methods are NOT isolated to MainActor by default definition, so we need 'nonisolated' + Task or assume Main if system guarantees.
// However, since we passed 'nil' queue, they run on main thread. To satify compiler in Strict Concurrency:
// We mark them nonisolated and bridge to MainActor, OR since we know it's main queue, we can leverage proper isolation if protocols were updated.
// Currently safest is nonisolated + assume main or Task.
// BUT, since we init with queue: nil, the callbacks ARE on main thread.
// We will use nonisolated and Task { @MainActor } to be strictly safe and explicit.

extension L2CAPManager: CBCentralManagerDelegate {
    
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            switch central.state {
            case .poweredOn:
                print("✅ Bluetooth is powered on")
                self.connectionState = .disconnected
            case .poweredOff:
                self.connectionState = .error("Bluetooth is powered off")
            case .unauthorized:
                self.connectionState = .error("Bluetooth is unauthorized")
            case .unsupported:
                self.connectionState = .error("Bluetooth is not supported")
            default:
                self.connectionState = .error("Unknown bluetooth state")
            }
        }
    }
    
    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        Task { @MainActor in
            // Capture peripheral in a Sendable way if possible, CBPeripheral is not Sendable but here it crosses boundary.
            // In Swift 6, passing CBPeripheral to MainActor task might warn. We accept it as it's a system object often used this way.
            // For strictness we could wrapper it, but let's proceed.
            if !self.discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
                self.discoveredDevices.append(peripheral)
            }
            print("📡 Discovered device: \(peripheral.name ?? "Unknown")")
        }
    }
    
    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            print("✅ Connected to \(peripheral.name ?? "Unknown")")
            self.connectionState = .connected
            if !self.connectedDevices.contains(where: { $0.identifier == peripheral.identifier }) {
                self.connectedDevices.append(peripheral)
            }
            
            // 서비스 검색
            peripheral.discoverServices([self.serviceUUID])
        }
    }
    
    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let errorDesc = error?.localizedDescription
        Task { @MainActor in
            print("❌ Failed to connect: \(errorDesc ?? "Unknown error")")
            self.connectionState = .error(errorDesc ?? "Connection failed")
        }
    }
    
    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            print("🔌 Disconnected from \(peripheral.name ?? "Unknown")")
            self.connectedDevices.removeAll { $0.identifier == peripheral.identifier }
            if self.connectedDevices.isEmpty {
                self.connectionState = .disconnected
            }
            // l2capChannel should be cleared
            self.disconnect() // calls internal cleanup
        }
    }
}

// MARK: - CBPeripheralDelegate
extension L2CAPManager: CBPeripheralDelegate {
    
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("❌ Error discovering services: \(error.localizedDescription)")
                return
            }
            
            guard let services = peripheral.services else { return }
            
            for service in services {
                print("🔍 Discovered service: \(service.uuid)")
                peripheral.discoverCharacteristics([self.l2capCharacteristicUUID], for: service)
            }
        }
    }
    
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("❌ Error discovering characteristics: \(error.localizedDescription)")
                return
            }
            
            guard let characteristics = service.characteristics else { return }
            
            for characteristic in characteristics {
                print("🔍 Discovered characteristic: \(characteristic.uuid)")
                
                // L2CAP PSM 읽기
                if characteristic.uuid == self.l2capCharacteristicUUID {
                    peripheral.readValue(for: characteristic)
                }
            }
        }
    }
    
    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Read value safely
        let data = characteristic.value
        
        Task { @MainActor in
            if let error = error {
                print("❌ Error reading characteristic: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else { return }
            
            // PSM 값 추출 (2바이트)
            if data.count >= 2 {
                let psm = data.withUnsafeBytes { $0.load(as: UInt16.self) }
                print("📡 Received L2CAP PSM: \(psm)")
                self.openL2CAPChannel(for: peripheral, psm: CBL2CAPPSM(psm))
            }
        }
    }
    
    nonisolated func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("❌ Error opening L2CAP channel: \(error.localizedDescription)")
                return
            }
            
            guard let channel = channel else {
                print("❌ L2CAP channel is nil")
                return
            }
            
            print("✅ L2CAP channel opened successfully")
            self.l2capChannel = channel
            
            // 입력 스트림 설정
            if let inputStream = channel.inputStream {
                inputStream.delegate = self
                inputStream.schedule(in: .main, forMode: .default)
                inputStream.open()
            }
            
            // 출력 스트림 설정
            if let outputStream = channel.outputStream {
                outputStream.delegate = self
                outputStream.schedule(in: .main, forMode: .default)
                outputStream.open()
            }
        }
    }
}

// MARK: - CBPeripheralManagerDelegate
extension L2CAPManager: CBPeripheralManagerDelegate {
    
    nonisolated func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        Task { @MainActor in
            switch peripheral.state {
            case .poweredOn:
                print("✅ Peripheral Manager is powered on")
            case .poweredOff:
                // could update state
                print("❌ Peripheral Manager is powered off")
            default:
                print("⚠️ Peripheral Manager state: \(peripheral.state.rawValue)")
            }
        }
    }
    
    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager, didPublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("❌ Error publishing L2CAP channel: \(error.localizedDescription)")
                return
            }
            
            print("✅ L2CAP channel published with PSM: \(PSM)")
            self.publishedL2CAPChannel = PSM
            
            // PSM을 특성에 저장하여 Central이 읽을 수 있도록 함
            let psmData = withUnsafeBytes(of: PSM.bigEndian) { Data($0) }
            let characteristic = CBMutableCharacteristic(
                type: self.l2capCharacteristicUUID,
                properties: [.read],
                value: psmData,
                permissions: [.readable]
            )
            
            let service = CBMutableService(type: self.serviceUUID, primary: true)
            service.characteristics = [characteristic]
            
            self.peripheralManager.add(service)
            
            // 광고 시작
            self.peripheralManager.startAdvertising([
                CBAdvertisementDataServiceUUIDsKey: [self.serviceUUID],
                CBAdvertisementDataLocalNameKey: "Counting App"
            ])
        }
    }
    
    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager, didUnpublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("❌ Error unpublishing L2CAP channel: \(error.localizedDescription)")
                return
            }
            print("✅ L2CAP channel unpublished")
        }
    }
    
    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("❌ Error opening L2CAP channel (peripheral): \(error.localizedDescription)")
                return
            }
            
            guard let channel = channel else {
                print("❌ L2CAP channel is nil (peripheral)")
                return
            }
            
            print("✅ L2CAP channel opened (peripheral mode)")
            self.l2capChannel = channel
            
            // 스트림 설정
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
    }
}

// MARK: - StreamDelegate
extension L2CAPManager: StreamDelegate {
    
    nonisolated func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        MainActor.assumeIsolated { 
            switch eventCode {
            case .hasBytesAvailable:
                if let inputStream = aStream as? InputStream {
                    self.readData(from: inputStream)
                }
                
            case .hasSpaceAvailable:
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
    }
}
