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

    var body: some View {
        ZStack {
            // QR 스캐너 카메라 뷰
            QRCameraView(isScanning: $isScanning) { result in
                handleScan(result: result)
            }
            .edgesIgnoringSafeArea(.all)
            .background(Color.black)
            
            // 오버레이 UI
            VStack(spacing: 30) {
                // 상단 타이틀
                Text("qr_scan_guide".localized)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                    .padding(.top, 80)
                
                Spacer()
                
                // 스캔 가이드 프레임 영역 (시각적 효과)
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.8), lineWidth: 4)
                    .frame(width: 250, height: 250)
                    .overlay(
                        Image(systemName: "viewfinder")
                            .font(.system(size: 60))
                            .foregroundStyle(.white.opacity(0.5))
                    )
                
                VStack(spacing: 12) {
                    Text("qr_scan_description".localized)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .shadow(radius: 2)
                }
                .padding(.top, 20)
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("import_category_title".localized, isPresented: $showingImportAlert) {
            Button("import".localized) {
                if let category = importedCategory {
                    importCategory(category)
                }
            }
            Button("cancel".localized, role: .cancel) {
                isScanning = true // 다시 스캔 재개
            }
        } message: {
            if let category = importedCategory {
                Text(String(format: "import_category_message".localized, category.name))
            }
        }
        .alert("camera_permission_required".localized, isPresented: $showingPermissionAlert) {
            Button("settings".localized) {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("cancel".localized, role: .cancel) {
                dismiss()
            }
        } message: {
            Text("camera_permission_message".localized)
        }

        .withLock()
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
                }
            }
        }
    }
    
    private func importCategory(_ category: TallyCategory) {
        store.importCategory(category)
        dismiss()
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
class QRCaptureService: NSObject, AVCaptureMetadataOutputObjectsDelegate {
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
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    if granted {
                        self?.setupSession(previewContainer: previewContainer)
                    } else {
                        self?.delegate?.didFail(error: QRCameraError.unauthorized)
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
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didFind(code: stringValue)
        }
    }
}
