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

struct BluetoothDeviceListView: View {
    @ObservedObject var l2capManager = L2CAPManager.shared
    @ObservedObject var permissionHelper = BluetoothPermissionHelper.shared
    @ObservedObject var l10n = LocalizationManager.shared
    
    @Environment(\.dismiss) var dismiss
    
    @State private var showPermissionAlert = false
    @State private var isScanning = false
    
    var body: some View {
        NavigationView {
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
                }
            }
            .navigationTitle("Bluetooth Devices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    scanButton
                }
            }
            .alert("Bluetooth Permission Required", isPresented: $showPermissionAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Settings") {
                    permissionHelper.openSettings()
                }
            } message: {
                Text("Please enable Bluetooth in Settings to connect with other devices.")
            }
            .onAppear {
                checkPermissionAndScan()
            }
            .onDisappear {
                l2capManager.stopScanning()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var connectionStatusHeader: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            Text(statusText)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
    
    private var deviceList: some View {
        List {
            // 연결된 기기
            if !l2capManager.connectedDevices.isEmpty {
                Section("Connected Devices") {
                    ForEach(l2capManager.connectedDevices, id: \.identifier) { device in
                        ConnectedDeviceRow(device: device)
                    }
                }
            }
            
            // 검색된 기기
            Section("Available Devices") {
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
                .foregroundColor(.secondary)
            
            Text("No Devices Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the scan button to search for nearby devices")
                .font(.subheadline)
                .foregroundColor(.secondary)
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
                    Text("Scanning")
                        .font(.subheadline)
                }
            } else {
                Image(systemName: "arrow.clockwise")
            }
        }
        .disabled(permissionHelper.permissionStatus != .authorized)
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
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .scanning:
            return "Scanning..."
        case .disconnected:
            return "Disconnected"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    // MARK: - Methods
    
    private func checkPermissionAndScan() {
        permissionHelper.checkPermission { status in
            if status == .authorized {
                startScanning()
            } else if status == .denied || status == .restricted {
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
                    .foregroundColor(.blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name ?? "Unknown Device")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(device.identifier.uuidString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                .foregroundColor(.green)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name ?? "Unknown Device")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Connected")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
#Preview {
    BluetoothDeviceListView()
}
