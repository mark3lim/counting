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
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var metadataOutput: AVCaptureMetadataOutput?
    var isRunning: Bool {
        return captureSession?.isRunning ?? false
    }
    
    // 중복 스캔 방지를 위한 변수
    private var lastScanTime: Date?
    private var lastScannedCode: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        checkPermission()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
        
        // 스캔 영역(rectOfInterest) 설정
        if let previewLayer = previewLayer, let metadataOutput = metadataOutput {
            // UI의 가이드 박스와 동일한 크기 (250x250) 및 위치 계산
            let size = 250.0
            let x = (view.bounds.width - size) / 2
            let y = (view.bounds.height - size) / 2
            let scanRect = CGRect(x: x, y: y, width: size, height: size)
            
            // 좌표 변환 (Device coordinates -> MetadataOutput coordinates)
            let rectOfInterest = previewLayer.metadataOutputRectConverted(fromLayerRect: scanRect)
            metadataOutput.rectOfInterest = rectOfInterest
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 뷰가 나타나면 스캔 시작
        if captureSession?.isRunning == false {
             DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                 self?.captureSession?.startRunning()
             }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
             DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                 self?.captureSession?.stopRunning()
             }
        }
    }
    
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCamera()
                    }
                } else {
                    DispatchQueue.main.async {
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
    
    private func setupCamera() {
        let session = AVCaptureSession()
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            delegate?.didFail(error: QRCameraError.setupFailed)
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            delegate?.didFail(error: QRCameraError.setupFailed)
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
            
            // 나중에 viewDidLayoutSubviews에서 rectOfInterest 설정
            self.metadataOutput = metadataOutput
        } else {
            delegate?.didFail(error: QRCameraError.setupFailed)
            return
        }
        
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        
        self.previewLayer = preview
        self.captureSession = session
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    func startScanning() {
        guard let session = captureSession, !session.isRunning else { return }
        // 스캔 재시작 시 디바운스 초기화
        lastScanTime = nil
        lastScannedCode = nil
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    func stopScanning() {
        guard let session = captureSession, session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            session.stopRunning()
        }
    }
}

extension QRScannerController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // 이미 캡처 세션이 멈춰있거나 할 때 중복 처리를 막기 위한 로직이 필요할 수 있음
        // UIViewControllerWrapper 에서 isScanning 바인딩으로 제어됨
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            // 스마트 디바운싱:
            // 1. 같은 코드인 경우: 2.0초 쿨타임 적용 (중복 인식 방지)
            // 2. 다른 코드인 경우: 즉시 인식 (반응성 향상)
            if stringValue == lastScannedCode, let lastTime = lastScanTime, Date().timeIntervalSince(lastTime) < 2.0 {
                return
            }
            
            lastScannedCode = stringValue
            lastScanTime = Date()
            
            // 진동 피드백
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            delegate?.didFind(code: stringValue)
        }
    }
}
