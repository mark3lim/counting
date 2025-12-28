//
//  QRCodeScannerView.swift
//  counting
//
//  Created by MARKLIM on 2025-12-20.
//  Updated for AVFoundation Camera Support
//

import SwiftUI
import AVFoundation

struct QRCodeScannerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: TallyStore
    
    @State private var showingImportAlert = false
    @State private var importedCategory: TallyCategory?
    @State private var scanResult: Result<String, Error>? = nil
    @State private var showingPermissionAlert = false
    
    // 스캔 후 잠시 멈춤을 위한 플래그
    @State private var isScanning = true

    // MARK: - Body
    var body: some View {
        ZStack {
            cameraLayer
            
            VStack(spacing: 0) {
                headerView
                Spacer()
                scanGuideView
                Spacer()
                descriptionView
                Spacer()
            }
            
            // 알림 토스트 (최상위 레이어)
            notificationToast
        }
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "overwrite_or_merge_title".localized,
            isPresented: $showingImportAlert,
            titleVisibility: .visible,
            actions: importActionButtons,
            message: importMessage
        )
        .alert("camera_permission_required".localized, isPresented: $showingPermissionAlert) {
            Button("settings".localized) {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("cancel".localized, role: .cancel) { dismiss() }
        } message: {
            Text("camera_permission_message".localized)
        }
        // iOS 17+ Modern Haptics
        .sensoryFeedback(.success, trigger: showingImportAlert)
        .sensoryFeedback(.error, trigger: showingPermissionAlert)
        .sensoryFeedback(.success, trigger: showNotification) { _, newValue in
            newValue && notificationType == .success
        }
        .sensoryFeedback(.error, trigger: showNotification) { _, newValue in
            newValue && notificationType == .error
        }
        .withLock()
    }
    
    // MARK: - Subviews
    
    private var cameraLayer: some View {
        QRCameraView(isScanning: $isScanning) { result in
            handleScan(result: result)
        }
        .edgesIgnoringSafeArea(.all)
        .background(Color.black)
    }
    
    private var headerView: some View {
        Text("qr_scan_guide".localized)
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.top, 60) // Adjusted for layout
    }
    
    private var scanGuideView: some View {
        // Rounded Rectangle Style (User Preference Match)
        RoundedRectangle(cornerRadius: 24)
            .strokeBorder(Color.white.opacity(0.8), lineWidth: 4)
            .frame(width: 250, height: 250)
            .overlay(
                Image(systemName: "viewfinder")
                    .font(.system(size: 60))
                    .foregroundStyle(.white.opacity(0.5))
            )
            .background(
                 Color.black.opacity(0.2)
                    .mask(RoundedRectangle(cornerRadius: 24).frame(width: 250, height: 250))
            )
    }
    
    private var descriptionView: some View {
        Text("qr_scan_description".localized)
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .shadow(radius: 2)
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
    
    // MARK: - Dialog Builders
    
    @ViewBuilder
    private func importActionButtons() -> some View {
        Button("save_as_is".localized) {
            if let category = importedCategory {
                importCategory(category, mode: .overwrite)
            }
        }
        
        Button("merge_sum".localized) {
            if let category = importedCategory {
                importCategory(category, mode: .merge)
            }
        }
        
        Button("cancel".localized, role: .cancel) {
            isScanning = true
        }
    }
    
    @ViewBuilder
    private func importMessage() -> some View {
        if let category = importedCategory {
            Text(String(format: "overwrite_or_merge_message".localized, category.name))
        }
    }

    // MARK: - Methods
    
    private func handleScan(result: Result<String, Error>) {
        switch result {
        case .success(let code):
            // QR 코드가 감지되면 스캔 중지
            isScanning = false
            processScannedCode(code)
            
        case .failure(let error):
            if let cameraError = error as? QRCameraError, cameraError == .unauthorized {
                showingPermissionAlert = true
            }
        }
    }
    
    private func processScannedCode(_ code: String) {
        // 무거운 디코딩 작업은 백그라운드 스레드에서 수행하여 UI 버벅임을 방지합니다.
        Task.detached(priority: .userInitiated) {
            // Base64 + Zlib 압축 해제
            guard let compressedData = Data(base64Encoded: code) else {
                await MainActor.run { self.isScanning = true }
                return
            }
            
            guard let decompressedData = try? (compressedData as NSData).decompressed(using: .zlib) as Data else {
                await MainActor.run { self.isScanning = true }
                return
            }
            
            // CategoryData 디코딩
            do {
                let data = try JSONDecoder().decode(CategoryData.self, from: decompressedData)
                
                // 결과 처리는 메인 스레드에서
                await MainActor.run {
                    // TallyCategory 생성
                    let category = TallyCategory(
                        id: data.id,
                        name: data.name,
                        colorName: data.colorName,
                        iconName: data.icon,
                        counters: data.counters
                    )
                    
                    self.importedCategory = category
                    self.showingImportAlert = true
                }
                
            } catch {
                await MainActor.run {
                    self.isScanning = true
                    self.showNotification(message: "qr_encode_failed".localized, type: .error)
                }
            }
        }
    }
    
    enum ImportMode {
        case overwrite
        case merge
    }
    
    // Notification State
    @State private var notificationMessage: String?
    @State private var notificationType: NotificationType = .success
    @State private var showNotification = false
    
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
    
    // Notification Helper
    private func showNotification(message: String, type: NotificationType) {
        notificationMessage = message
        notificationType = type
        withAnimation(.spring()) {
            showNotification = true
        }
        
        // 2초 후 자동 숨김
        Task {
            try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
            await MainActor.run {
                withAnimation {
                    showNotification = false
                }
            }
        }
    }

    private func importCategory(_ category: TallyCategory, mode: ImportMode) {
        switch mode {
        case .overwrite:
            store.importCategory(category)
        case .merge:
            store.mergeCategory(category)
        }
        
        // 성공 알림 표시
        showNotification(message: "sync_success".localized, type: .success)
        
        // 알림이 보여질 시간을 주기 위해 약간 지연 후 dismiss (선택적) 또는 dismiss 후 홈에서 보여줄지 결정.
        // 여기서는 뷰가 dismiss 되므로 알림을 볼 시간이 없을 수 있음.
        // 하지만 요청은 "성공, 실패 시 알림이 2초 동안 나오게 해줘"임.
        // dismiss를 2초 지연시킴.
        Task {
            try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
            await MainActor.run {
                dismiss()
            }
        }
    }
}

// MARK: - QR Camera Implementation

enum QRCameraError: Error {
    case unauthorized
    case setupFailed
}

struct QRCameraView: UIViewControllerRepresentable {
    @Binding var isScanning: Bool
    var onResult: (Result<String, Error>) -> Void
    
    func makeUIViewController(context: Context) -> QRScannerController {
        let controller = QRScannerController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRScannerController, context: Context) {
        if isScanning {
            if !uiViewController.isRunning {
                uiViewController.startScanning()
            }
        } else {
            if uiViewController.isRunning {
                uiViewController.stopScanning()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate, QRScannerControllerDelegate {
        let parent: QRCameraView
        
        init(parent: QRCameraView) {
            self.parent = parent
        }
        
        func didFind(code: String) {
            parent.onResult(.success(code))
        }
        
        func didFail(error: Error) {
            parent.onResult(.failure(error))
        }
    }
}

protocol QRScannerControllerDelegate: AnyObject {
    func didFind(code: String)
    func didFail(error: Error)
}

class QRScannerController: UIViewController {
    weak var delegate: QRScannerControllerDelegate? {
        didSet {
            // delegate가 설정될 때마다 captureService에도 동기화
            captureService.delegate = delegate
        }
    }
    private let captureService = QRCaptureService()
    
    var isRunning: Bool {
        return captureService.isRunning
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        // delegate는 didSet에서 자동 동기화됨
        captureService.checkPermission(previewContainer: view)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        captureService.updatePreviewFrame(bounds: view.layer.bounds)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        captureService.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureService.stop()
    }
    
    func startScanning() {
        captureService.start()
    }
    
    func stopScanning() {
        captureService.stop()
    }
}

// MARK: - QR Capture Service (Swift 6 Concurrency Safe)

@MainActor
final class QRCaptureService: NSObject, AVCaptureMetadataOutputObjectsDelegate, @unchecked Sendable {
    weak var delegate: QRScannerControllerDelegate?
    
    // AVCaptureSession은 Thread-safe하므로 nonisolated로 선언하여 백그라운드 접근 허용
    nonisolated private let session = AVCaptureSession()
    // 세션 조작을 위한 전용 Serial Queue (nonisolated)
    nonisolated private let sessionQueue = DispatchQueue(label: "com.counting.cameraSessionQueue")
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // 상태 변수 (MainActor isolated)
    private var lastScanTime: Date?
    private var lastScannedCode: String?
    
    nonisolated var isRunning: Bool {
        return session.isRunning
    }
    
    func checkPermission(previewContainer: UIView) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession(previewContainer: previewContainer)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    if granted {
                        self.setupSession(previewContainer: previewContainer)
                    } else {
                        self.delegate?.didFail(error: QRCameraError.unauthorized)
                    }
                }
            }
        case .denied, .restricted:
            delegate?.didFail(error: QRCameraError.unauthorized)
        @unknown default:
            delegate?.didFail(error: QRCameraError.setupFailed)
        }
    }
    
    private func setupSession(previewContainer: UIView) {
        // 프리뷰 레이어 설정 (Main Thread)
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = previewContainer.layer.bounds
        previewContainer.layer.addSublayer(preview)
        self.previewLayer = preview
        
        // 세션 구성 및 시작 (Background)
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.configureSession()
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    nonisolated private func configureSession() {
        session.beginConfiguration()
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            Task { @MainActor in self.notifySetupFailed() }
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            Task { @MainActor in self.notifySetupFailed() }
            session.commitConfiguration()
            return
        }
        
        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            // Delegate 설정. self는 @MainActor지만, NSObject는 reference type이라 전달 가능.
            // Delegate 콜백 큐는 Main으로 지정.
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]
        } else {
             Task { @MainActor in self.notifySetupFailed() }
            session.commitConfiguration()
            return
        }
        
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        } catch {}
        
        session.commitConfiguration()
    }
    
    private func notifySetupFailed() {
        delegate?.didFail(error: QRCameraError.setupFailed)
    }
    
    func start() {
        lastScanTime = nil
        lastScannedCode = nil
        
        sessionQueue.async { [weak self] in
            guard let self = self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }
    
    func stop() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }
    
    func updatePreviewFrame(bounds: CGRect) {
        previewLayer?.frame = bounds
    }
    
    // Delegate Method (MainActor)
    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        Task { @MainActor in
            self.handleMetadata(metadataObjects)
        }
    }
    
    private func handleMetadata(_ metadataObjects: [AVMetadataObject]) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                  let stringValue = readableObject.stringValue else {
                return
            }
            
            // Smart Debounce
            if stringValue == lastScannedCode, let lastTime = lastScanTime, Date().timeIntervalSince(lastTime) < 2.0 {
                return
            }
            
            lastScannedCode = stringValue
            lastScanTime = Date()
            

            delegate?.didFind(code: stringValue)
        }
    }
}
