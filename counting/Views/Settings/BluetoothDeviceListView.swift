//
//  BluetoothDeviceListView.swift
//  counting
//
//  Created by MARKLIM on 2025-12-19.
//
//  L2CAP 블루투스 기기 검색 및 연결 화면
//

import SwiftUI
import CoreBluetooth
import CoreImage.CIFilterBuiltins

struct BluetoothDeviceListView: View {
    let category: TallyCategory
    
    @ObservedObject var l2capManager = L2CAPManager.shared
    @ObservedObject var permissionHelper = BluetoothPermissionHelper.shared
    @ObservedObject var l10n = LocalizationManager.shared
    
    @Environment(\.dismiss) var dismiss
    
    @State private var showPermissionAlert = false
    @State private var isScanning = false
    
    var body: some View {
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
                
                // QR 코드 공유 버튼
                qrCodeShareButton
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
        }
        .navigationTitle("bluetooth_devices".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
        .onAppear {
            checkPermissionAndScan()
        }
        .onDisappear {
            l2capManager.stopScanning()
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
    
    private var qrCodeShareButton: some View {
        NavigationLink {
            CategoryQRCodeView(category: category)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "qrcode")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("qr_share".localized)
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
    
    // MARK: - Methods
    
    private func checkPermissionAndScan() {
        permissionHelper.checkPermission { status in
            if status == .authorized {
                startScanning()
            } else if status == .denied || status == .restricted {
                // 권한이 없는 경우 (우선 순위 1)
                showPermissionAlert = true
            } else if status == .poweredOff {
                // 권한은 있으나 기능이 꺼진 경우 (우선 순위 2)
                showPermissionAlert = true
            }
        }
    }
    
    private func toggleScanning() {
        if isScanning {
            stopScanning()
        } else {
            startScanning()
        }
    }
    
    private func startScanning() {
        isScanning = true
        l2capManager.startScanning()
        
        // 30초 후 자동 중지
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            if isScanning {
                stopScanning()
            }
        }
    }
    
    private func stopScanning() {
        isScanning = false
        l2capManager.stopScanning()
    }
    
    private func connectToDevice(_ device: CBPeripheral) {
        stopScanning()
        l2capManager.connect(to: device)
    }
}

// MARK: - Device Row
struct DeviceRow: View {
    let device: CBPeripheral
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "iphone")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name ?? "Unknown Device")
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    Text(device.identifier.uuidString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Connected Device Row
struct ConnectedDeviceRow: View {
    let device: CBPeripheral
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name ?? "Unknown Device")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text("connected".localized)
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
