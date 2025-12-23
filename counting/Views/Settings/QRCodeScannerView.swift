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
        NavigationStack {
            ZStack {
                // QR 스캐너 카메라 뷰
                QRCameraView(isScanning: $isScanning) { result in
                    handleScan(result: result)
                }
                .edgesIgnoringSafeArea(.all)
                .background(Color.black)
                
                // 오버레이 UI
                VStack(spacing: 30) {
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
                    
                    Text("qr_scan_guide".localized)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.top, 20)
                        .shadow(radius: 2)

                    Text("qr_scan_description".localized)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .shadow(radius: 2)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
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
        }
        .withLock()
    }
    
    // MARK: - Methods
    
    private func handleScan(result: Result<String, Error>) {
        switch result {
        case .success(let code):
            // QR 코드가 감지되면 스캔 중지
            isScanning = false
            
            // 1. Base64 + Zlib 압축 해제 시도 (새 방식)
            if let compressedData = Data(base64Encoded: code) {
                // NSData.decompressed(using: .zlib) 사용 (iOS 13+ 표준)
                if let decompressedData = try? (compressedData as NSData).decompressed(using: .zlib) as Data,
                   let category = try? JSONDecoder().decode(TallyCategory.self, from: decompressedData) {
                    importedCategory = category
                    showingImportAlert = true
                    return
                }
            }
            
            // 2. 일반 JSON 문자열 디코딩 시도 (이전 버전 호환성 / 압축 실패 시)
            if let data = code.data(using: .utf8) {
                do {
                    let category = try JSONDecoder().decode(TallyCategory.self, from: data)
                    importedCategory = category
                    showingImportAlert = true
                } catch {
                    print("JSON Decode Error: \(error)")
                    // 실패 시 다시 스캔 재개 (또는 에러 메시지 표시)
                    // 잠깐 딜레이 후 재개
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isScanning = true
                    }
                }
            }
        case .failure(let error):
            print("Scanning Error: \(error.localizedDescription)")
            if let cameraError = error as? QRCameraError, cameraError == .unauthorized {
                showingPermissionAlert = true
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
    weak var delegate: QRScannerControllerDelegate?
    private let captureService = QRCaptureService()
    
    var isRunning: Bool {
        return captureService.isRunning
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        captureService.delegate = delegate
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
// AVCaptureSession 로직을 별도 클래스로 분리하여 책임을 명확히 하고 스레드 안전성을 보장합니다.
class QRCaptureService: NSObject {
    weak var delegate: QRScannerControllerDelegate?
    
    private let session = AVCaptureSession()
    // 세션 조작을 위한 전용 Serial Queue (메인 스레드 블로킹 방지)
    private let sessionQueue = DispatchQueue(label: "com.counting.cameraSessionQueue")
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var metadataOutput: AVCaptureMetadataOutput?
    
    // 중복 스캔 방지 (메인 스레드에서만 접근)
    private var lastScanTime: Date?
    private var lastScannedCode: String?
    
    var isRunning: Bool {
        return session.isRunning
    }
    
    func checkPermission(previewContainer: UIView) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession(previewContainer: previewContainer)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupSession(previewContainer: previewContainer)
                } else {
                    DispatchQueue.main.async { self?.delegate?.didFail(error: QRCameraError.unauthorized) }
                }
            }
        case .denied, .restricted:
            delegate?.didFail(error: QRCameraError.unauthorized)
        @unknown default:
            delegate?.didFail(error: QRCameraError.setupFailed)
        }
    }
    
    private func setupSession(previewContainer: UIView) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.configureSession()
            
            DispatchQueue.main.async {
                let preview = AVCaptureVideoPreviewLayer(session: self.session)
                preview.videoGravity = .resizeAspectFill
                preview.frame = previewContainer.layer.bounds
                previewContainer.layer.addSublayer(preview)
                self.previewLayer = preview
                
                self.start()
            }
        }
    }
    
    private func configureSession() {
        session.beginConfiguration()
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            notifySetupFailed()
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            notifySetupFailed()
            session.commitConfiguration()
            return
        }
        
        // Metadata Output 설정
        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = [.qr]
            self.metadataOutput = output
        } else {
            notifySetupFailed()
            session.commitConfiguration()
            return
        }
        
        // Auto Focus & Exposure 설정
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        } catch {
            print("Failed to configure focus: \(error)")
        }
        
        session.commitConfiguration()
    }
    
    private func notifySetupFailed() {
        DispatchQueue.main.async {
            self.delegate?.didFail(error: QRCameraError.setupFailed)
        }
    }
    
    func start() {
        // 변수 초기화는 메인 스레드에서 (Delegate도 메인에서 실행되므로 안전)
        DispatchQueue.main.async {
            self.lastScanTime = nil
            self.lastScannedCode = nil
        }
        
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
        // UI 업데이트는 항상 메인 스레드에서 호출됨
        previewLayer?.frame = bounds
        
        if let preview = previewLayer, let output = metadataOutput {
            // RectOfInterest 계산 (250x250 가이드 박스 기준)
            let size = 250.0
            let x = (bounds.width - size) / 2
            let y = (bounds.height - size) / 2
            let scanRect = CGRect(x: x, y: y, width: size, height: size)
            
            output.rectOfInterest = preview.metadataOutputRectConverted(fromLayerRect: scanRect)
        }
    }
}

extension QRCaptureService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                  let stringValue = readableObject.stringValue else { return }
            
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
