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
    // MARK: - Environments
    @Environment(\.dismiss) var dismiss
    @Binding var isPresented: Bool
    @EnvironmentObject var store: TallyStore
    
    // MARK: - Observed Objects
    @ObservedObject var l2capManager = L2CAPManager.shared
    @ObservedObject var permissionHelper = BluetoothPermissionHelper.shared
    @ObservedObject var l10n = LocalizationManager.shared
    
    // MARK: - State
    @State private var showPermissionAlert = false
    @State private var isScanning = false
    @State private var autoStopTask: Task<Void, Never>?
    
    // Import & Notification State
    @State private var receivedCategory: TallyCategory?
    @State private var showingImportAlert = false
    @State private var showNotification = false
    @State private var notificationMessage: String?
    @State private var notificationType: NotificationType = .success
    
    // MARK: - Types
    enum NotificationType {
        case success
        case error
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.circle.fill"
            }
        }
    }
    
    enum ImportMode {
        case overwrite
        case merge
    }
    
    // MARK: - Body
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
                
                // QR 코드 스캔 버튼
                qrCodeScanButton
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
            
            // 알림 토스트 (최상위 레이어)
            notificationToast
        }
        .navigationTitle("import_data".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                scanButton
            }
        }
        // 권한 알림
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
        // 가져오기 확인 다이얼로그
        .confirmationDialog(
            "overwrite_or_merge_title".localized,
            isPresented: $showingImportAlert,
            titleVisibility: .visible
        ) {
            Button("save_as_is".localized) {
                if let category = receivedCategory {
                    importCategory(category, mode: .overwrite)
                }
            }
            
            Button("merge_sum".localized) {
                if let category = receivedCategory {
                    importCategory(category, mode: .merge)
                }
            }
            
            Button("cancel".localized, role: .cancel) {
                receivedCategory = nil
            }
        } message: {
            if let category = receivedCategory {
                Text(String(format: "overwrite_or_merge_message".localized, category.name))
            }
        }
        // Lifecycle & Data Monitoring
        .task {
            await checkPermissionAndScan()
        }
        .onDisappear {
            stopScanning()
        }
        .onChange(of: l2capManager.receivedData) { _, newData in
            Task { @MainActor in
                handleReceivedData(newData)
            }
        }
        // Haptic Feedback
        .sensoryFeedback(.success, trigger: showingImportAlert)
        .sensoryFeedback(.success, trigger: showNotification) { _, newValue in
            newValue && notificationType == .success
        }
        .sensoryFeedback(.error, trigger: showNotification) { _, newValue in
            newValue && notificationType == .error
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
        NavigationLink {
            QRCodeScannerView(rootIsPresented: $isPresented)
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
    
    @ViewBuilder
    private var notificationToast: some View {
        if showNotification, let message = notificationMessage {
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    Image(systemName: notificationType.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(notificationType.color)
                    
                    Text(message)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(.regularMaterial, in: Capsule())
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                .padding(.bottom, 50)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(100)
            }
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
    
    @MainActor
    private func checkPermissionAndScan() async {
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
        autoStopTask?.cancel()
        
        isScanning = true
        l2capManager.startScanning()
        
        // 30초 후 자동 중지
        autoStopTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(30))
                if isScanning {
                    stopScanning()
                }
            } catch {
                // Task 취소됨 (정상)
            }
        }
    }
    
    @MainActor
    private func stopScanning() {
        autoStopTask?.cancel()
        autoStopTask = nil
        
        isScanning = false
        l2capManager.stopScanning()
    }
    
    private func connectToDevice(_ device: CBPeripheral) {
        stopScanning()
        l2capManager.connect(to: device)
    }
    
    // MARK: - Import Logic
    
    @MainActor
    private func handleReceivedData(_ data: Data?) {
        guard let data = data else { return }
        
        do {
            let categoryData = try JSONDecoder().decode(CategoryData.self, from: data)
            let category = TallyCategory(
                id: categoryData.id,
                name: categoryData.name,
                colorName: categoryData.colorName,
                iconName: categoryData.icon,
                counters: categoryData.counters
            )
            
            self.receivedCategory = category
            self.showingImportAlert = true
            
        } catch {
            showNotification(message: "import_failed".localized, type: .error)
        }
        
        // 데이터 처리 완료 후 초기화 (MainActor)
        l2capManager.receivedData = nil
    }
    
    private func importCategory(_ category: TallyCategory, mode: ImportMode) {
        switch mode {
        case .overwrite:
            store.importCategory(category)
        case .merge:
            store.mergeCategory(category)
        }
        
        showNotification(message: "import_success".localized, type: .success)
        
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            await MainActor.run {
                withAnimation { showNotification = false }
                isPresented = false // Return to HomeView
            }
        }
    }
    
    private func showNotification(message: String, type: NotificationType) {
        notificationMessage = message
        notificationType = type
        withAnimation(.spring()) {
            showNotification = true
        }
    }
}
