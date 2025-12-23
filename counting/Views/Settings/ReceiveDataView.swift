//
//  ReceiveDataView.swift
//  counting
//
//  데이터 받기 화면 (블루투스 + QR 코드 스캔)
//  Swift 6 Concurrency 준수
//

import SwiftUI
import CoreBluetooth

struct ReceiveDataView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: TallyStore
    @ObservedObject var l2capManager = L2CAPManager.shared
    @ObservedObject var permissionHelper = BluetoothPermissionHelper.shared
    @ObservedObject var l10n = LocalizationManager.shared
    
    @State private var showPermissionAlert = false
    @State private var isScanning = false
    @State private var showQRScanner = false
    @State private var autoStopTask: Task<Void, Never>?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 배경
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // 연결 상태 헤더
                    connectionStatusHeader
                    
                    // 기기 목록
                    if l2capManager.discoveredDevices.isEmpty && !isScanning {
                        emptyStateView
                    } else {
                        deviceList
                    }
                    
                    // QR 코드 스캔 버튼
                    qrCodeScanButton
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("import_data".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    scanButton
                }
            }
            .alert(
                permissionHelper.permissionStatus == .poweredOff ? "bluetooth_powered_off".localized : "bluetooth_permission_required".localized,
                isPresented: $showPermissionAlert
            ) {
                Button("cancel".localized, role: .cancel) { }
                Button("settings".localized) {
                    permissionHelper.openSettings()
                }
            } message: {
                Text(permissionHelper.permissionStatus == .poweredOff ? "enable_bluetooth_message".localized : "bluetooth_permission_denied_message".localized)
            }
            .task {
                await checkPermissionAndScan()
            }
            .onDisappear {
                stopScanning()
            }
            .sheet(isPresented: $showQRScanner) {
                QRCodeScannerView()
                    .onAppear {
                        // QR 스캐너 진입 시 블루투스 스캔 중지
                        stopScanning()
                    }
            }
        }
        .withLock()
    }
    
    // MARK: - Subviews
    
    private var connectionStatusHeader: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
    
    private var deviceList: some View {
        List {
            // 연결된 기기
            if !l2capManager.connectedDevices.isEmpty {
                Section("connected_devices".localized) {
                    ForEach(l2capManager.connectedDevices, id: \.identifier) { device in
                        ConnectedDeviceRow(device: device)
                    }
                }
            }
            
            // 검색된 기기
            Section("available_devices".localized) {
                ForEach(l2capManager.discoveredDevices, id: \.identifier) { device in
                    DeviceRow(device: device) {
                        connectToDevice(device)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("no_devices_found".localized)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("tap_scan_button".localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var scanButton: some View {
        Button(action: toggleScanning) {
            if isScanning {
                HStack(spacing: 4) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("scanning".localized)
                        .font(.subheadline)
                }
            } else {
                Image(systemName: "arrow.clockwise")
            }
        }
        .disabled(permissionHelper.permissionStatus != .authorized)
    }
    
    private var qrCodeScanButton: some View {
        Button {
            showQRScanner = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("receive_via_qr".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.blue)
            .cornerRadius(16)
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch l2capManager.connectionState {
        case .connected:
            return .green
        case .connecting, .scanning:
            return .orange
        case .disconnected:
            return .gray
        case .error:
            return .red
        }
    }
    
    private var statusText: String {
        switch l2capManager.connectionState {
        case .connected:
            return "connected".localized
        case .connecting:
            return "connecting".localized
        case .scanning:
            return "scanning".localized
        case .disconnected:
            return "disconnected".localized
        case .error(let message):
            return "\("error".localized): \(message)"
        }
    }
    
    // MARK: - Methods (Swift 6 Concurrency)
    
    @MainActor
    private func checkPermissionAndScan() async {
        // 콜백 기반 API를 async로 래핑
        let status = await withCheckedContinuation { continuation in
            permissionHelper.checkPermission { status in
                continuation.resume(returning: status)
            }
        }
        
        if status == .authorized {
            startScanning()
        } else if status == .denied || status == .restricted || status == .poweredOff {
            showPermissionAlert = true
        }
    }
    
    private func toggleScanning() {
        if isScanning {
            stopScanning()
        } else {
            startScanning()
        }
    }
    
    @MainActor
    private func startScanning() {
        // 이전 타이머 취소
        autoStopTask?.cancel()
        
        isScanning = true
        l2capManager.startScanning()
        
        // 30초 후 자동 중지 (Task 사용)
        autoStopTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(30))
                if isScanning {
                    stopScanning()
                }
            } catch {
                // Task가 취소된 경우 (정상 동작)
            }
        }
    }
    
    @MainActor
    private func stopScanning() {
        // 타이머 취소
        autoStopTask?.cancel()
        autoStopTask = nil
        
        isScanning = false
        l2capManager.stopScanning()
    }
    
    private func connectToDevice(_ device: CBPeripheral) {
        stopScanning()
        l2capManager.connect(to: device)
    }
}
