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
    
    // 2단계 스캔 상태
    @State private var currentScanStep: Int = 1  // 1 또는 2
    @State private var scannedBasicInfo: CategoryBasicInfo?
    @State private var showStepGuide = false
    @State private var showStep1CompleteAlert = false  // 1단계 완료 알림
    
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
                // 상단 단계 표시
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        ForEach(1...2, id: \.self) { step in
                            Circle()
                                .fill(step <= currentScanStep ? Color.green : Color.white.opacity(0.3))
                                .frame(width: 12, height: 12)
                        }
                    }
                    
                    Text("qr_step_\(currentScanStep)_of_2".localized)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                }
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
                    Text(currentScanStep == 1 ? "qr_basic_info_title".localized : "qr_counting_data_title".localized)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .shadow(radius: 2)

                    Text(currentScanStep == 1 ? "qr_basic_info_description".localized : "qr_counting_data_description".localized)
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
        .alert("qr_step1_complete_title".localized, isPresented: $showStep1CompleteAlert) {
            Button("qr_step2_start_button".localized) {
                withAnimation {
                    currentScanStep = 2
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isScanning = true
                }
            }
            Button("cancel".localized, role: .cancel) {
                currentScanStep = 1
                scannedBasicInfo = nil
                isScanning = true
            }
        } message: {
            if let basicInfo = scannedBasicInfo {
                Text("\(basicInfo.name)\n\n\("qr_step1_complete_message".localized)")
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
            
            if currentScanStep == 1 {
                // 1단계: 기본 정보 스캔
                handleBasicInfoScan(code: code)
            } else {
                // 2단계: 카운팅 데이터 스캔
                handleCountingDataScan(code: code)
            }
            
        case .failure(let error):
            if let cameraError = error as? QRCameraError, cameraError == .unauthorized {
                showingPermissionAlert = true
            }
        }
    }
    
    private func handleBasicInfoScan(code: String) {
        
        // Base64 + Zlib 압축 해제
        guard let compressedData = Data(base64Encoded: code) else {
            DispatchQueue.main.async {
                isScanning = true
            }
            return
        }
        
        
        guard let decompressedData = try? (compressedData as NSData).decompressed(using: .zlib) as Data else {
            DispatchQueue.main.async {
                isScanning = true
            }
            return
        }
        
        
        // CategoryBasicInfo 디코딩
        do {
            let basicInfo = try JSONDecoder().decode(CategoryBasicInfo.self, from: decompressedData)
            
            scannedBasicInfo = basicInfo
            
            // 1단계 완료 알림 표시 (사용자가 확인 버튼을 누르면 2단계로 진행)
            DispatchQueue.main.async {
                showStep1CompleteAlert = true
            }
        } catch {
            DispatchQueue.main.async {
                isScanning = true
            }
        }
    }
    
    private func handleCountingDataScan(code: String) {
        
        guard let basicInfo = scannedBasicInfo else {
            currentScanStep = 1
            isScanning = true
            return
        }
        
        
        // Base64 + Zlib 압축 해제
        guard let compressedData = Data(base64Encoded: code) else {
            DispatchQueue.main.async {
                isScanning = true
            }
            return
        }
        
        
        guard let decompressedData = try? (compressedData as NSData).decompressed(using: .zlib) as Data else {
            DispatchQueue.main.async {
                isScanning = true
            }
            return
        }
        
        
        // CategoryCountingData 디코딩
        do {
            let countingData = try JSONDecoder().decode(CategoryCountingData.self, from: decompressedData)
            
            // ID가 일치하는지 확인
            guard countingData.categoryId == basicInfo.id else {
                currentScanStep = 1
                scannedBasicInfo = nil
                isScanning = true
                return
            }
            
            
            // 완전한 TallyCategory 구성
            if let completeCategory = mergeScannedData(basicInfo: basicInfo, countingData: countingData) {
                importedCategory = completeCategory
                showingImportAlert = true
            } else {
                DispatchQueue.main.async {
                    currentScanStep = 1
                    scannedBasicInfo = nil
                    isScanning = true
                }
            }
        } catch {
            DispatchQueue.main.async {
                isScanning = true
            }
        }
    }
    
    private func mergeScannedData(basicInfo: CategoryBasicInfo, countingData: CategoryCountingData) -> TallyCategory? {
        
        // TallyCategory 생성 - colorName을 직접 사용!
        let category = TallyCategory(
            id: basicInfo.id,
            name: basicInfo.name,
            colorName: basicInfo.colorName,  // 문자열 그대로 사용
            iconName: basicInfo.icon,
            counters: countingData.counters
        )
        
        return category
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
            
            // 세션 시작 (configuration 완료 후 바로)
            if !self.session.isRunning {
                self.session.startRunning()
            }
            
            // 프리뷰 레이어는 메인 스레드에서 설정
            DispatchQueue.main.async {
                let preview = AVCaptureVideoPreviewLayer(session: self.session)
                preview.videoGravity = .resizeAspectFill
                preview.frame = previewContainer.layer.bounds
                previewContainer.layer.addSublayer(preview)
                self.previewLayer = preview
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
    }
}

extension QRCaptureService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
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
