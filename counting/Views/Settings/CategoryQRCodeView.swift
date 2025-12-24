//
//  CategoryQRCodeView.swift
//  counting
//
//  Created by MARKLIM on 2025-12-20.
//
//  카테고리 데이터를 2단계 QR 코드로 표시하는 뷰 (iOS 26 Liquid Glass)
//

import SwiftUI
import CoreImage.CIFilterBuiltins

/// QR 코드 단계 정의
enum QRCodeStep: Int {
    case basicInfo = 0  // 카테고리 기본 정보 (이름, 색상, 아이콘)
    case countingData = 1  // 카운팅 데이터 (카운터들과 값)
}

/// 카테고리 기본 정보 전용 구조체
struct CategoryBasicInfo: Codable {
    let id: UUID
    let name: String
    let icon: String
    let colorData: Data  // Color를 Data로 인코딩
    
    init(from category: TallyCategory) {
        self.id = category.id
        self.name = category.name
        self.icon = category.iconName
        self.colorData = try! NSKeyedArchiver.archivedData(withRootObject: UIColor(category.color), requiringSecureCoding: false)
    }
}

/// 카운팅 데이터 전용 구조체
struct CategoryCountingData: Codable {
    let categoryId: UUID
    let counters: [TallyCounter]
    
    init(from category: TallyCategory) {
        self.categoryId = category.id
        self.counters = category.counters
    }
}

struct CategoryQRCodeView: View {
    let category: TallyCategory
    
    @Environment(\.dismiss) var dismiss
    @State private var currentStep: QRCodeStep = .basicInfo
    @State private var basicInfoQRImage: UIImage?
    @State private var countingDataQRImage: UIImage?
    @State private var errorMessage: String?
    
    // Constants
    private let qrScale: CGFloat = 10.0
    private let qrSize: CGFloat = 280.0
    private let maxDataSize = 2500
    
    var body: some View {
        ZStack {
            // iOS 26 Liquid Glass 배경
            liquidGlassBackground
            
            ScrollView {
                VStack(spacing: 24) {
                    // 상단 가이드
                    guideHeader
                        .padding(.top, 20)
                    
                    // 단계 표시기
                    stepIndicator
                    
                    // QR 코드 카드
                    qrCodeCard
                    
                    // 설명 카드
                    descriptionCard
                    
                    // 네비게이션 버튼
                    navigationButtons
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(category.name)
        .onAppear {
            generateAllQRCodes()
        }
    }
    
    // MARK: - View Components
    
    /// Liquid Glass 배경 (iOS 26)
    private var liquidGlassBackground: some View {
        ZStack {
            // 베이스 그라데이션
            LinearGradient(
                colors: [
                    category.color.opacity(0.25),
                    category.color.opacity(0.12),
                    category.color.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Liquid Glass 효과를 위한 오버레이
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.3)
        }
        .ignoresSafeArea()
    }
    
    /// 상단 가이드 헤더
    private var guideHeader: some View {
        VStack(spacing: 12) {
            // 카테고리 아이콘
            Image(systemName: category.icon)
                .font(.system(size: 50, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [category.color, category.color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: category.color.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // 카테고리 이름
            Text(category.name)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            // 2단계 안내
            HStack(spacing: 6) {
                Image(systemName: "qrcode")
                    .font(.system(size: 14, weight: .semibold))
                Text("qr_two_step_guide".localized)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }
    
    /// 단계 표시기
    private var stepIndicator: some View {
        HStack(spacing: 12) {
            // Step 1
            stepBadge(
                step: .basicInfo,
                isActive: currentStep == .basicInfo,
                isCompleted: currentStep == .countingData
            )
            
            // 연결선
            Rectangle()
                .fill(currentStep == .countingData ? category.color : Color.gray.opacity(0.3))
                .frame(height: 2)
                .frame(maxWidth: 60)
            
            // Step 2
            stepBadge(
                step: .countingData,
                isActive: currentStep == .countingData,
                isCompleted: false
            )
        }
        .padding(.horizontal)
    }
    
    /// 개별 단계 배지
    private func stepBadge(step: QRCodeStep, isActive: Bool, isCompleted: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                // 외곽 원
                Circle()
                    .stroke(
                        isActive || isCompleted ? category.color : Color.gray.opacity(0.3),
                        lineWidth: 2
                    )
                    .frame(width: 40, height: 40)
                
                // 내부 원 또는 체크마크
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(category.color)
                        )
                } else if isActive {
                    Circle()
                        .fill(category.color)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text("\(step.rawValue + 1)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        )
                } else {
                    Text("\(step.rawValue + 1)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.gray.opacity(0.5))
                }
            }
            
            // 단계 텍스트
            Text(step == .basicInfo ? "qr_step_1_of_2".localized : "qr_step_2_of_2".localized)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isActive ? .primary : .secondary)
        }
    }
    
    /// QR 코드 카드 (Liquid Glass 스타일)
    private var qrCodeCard: some View {
        VStack(spacing: 16) {
            // QR 코드 타이틀
            Text(currentStep == .basicInfo ? "qr_basic_info_title".localized : "qr_counting_data_title".localized)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            
            // QR 코드 이미지
            if let qrImage = currentStep == .basicInfo ? basicInfoQRImage : countingDataQRImage {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: qrSize, height: qrSize)
                    .padding(24)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: category.color.opacity(0.2), radius: 20, x: 0, y: 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.5), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            } else if let error = errorMessage {
                errorView(message: error)
            } else {
                loadingView
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
        )
    }
    
    /// 설명 카드
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(category.color)
                
                Text(currentStep == .basicInfo ? "qr_basic_info_description".localized : "qr_counting_data_description".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
    
    /// 정보 행
    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.secondary)
        }
    }
    
    /// 네비게이션 버튼
    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if currentStep == .countingData {
                // 이전 버튼
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        currentStep = .basicInfo
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("qr_step_1_of_2".localized)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                }
            }
            
            // 다음/완료 버튼
            Button {
                if currentStep == .basicInfo {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        currentStep = .countingData
                    }
                } else {
                    dismiss()
                }
            } label: {
                HStack(spacing: 8) {
                    Text(currentStep == .basicInfo ? "next".localized : "done".localized)
                        .font(.system(size: 16, weight: .bold))
                    
                    if currentStep == .basicInfo {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [category.color, category.color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: category.color.opacity(0.3), radius: 10, x: 0, y: 5)
                )
            }
        }
    }
    
    /// 에러 뷰
    private func errorView(message: String) -> some View {
        VStack(spacing: 15) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            
            Text(message)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(width: qrSize, height: qrSize)
        .background(Color.white.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    /// 로딩 뷰
    private var loadingView: some View {
        VStack(spacing: 15) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(category.color)
            
            Text("generating_qr_code".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(width: qrSize, height: qrSize)
        .background(Color.white.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    // MARK: - Methods
    
    /// 모든 QR 코드 생성
    private func generateAllQRCodes() {
        Task.detached(priority: .userInitiated) {
            // 1단계: 기본 정보 QR 코드
            await generateBasicInfoQRCode()
            
            // 2단계: 카운팅 데이터 QR 코드
            await generateCountingDataQRCode()
        }
    }
    
    /// 기본 정보 QR 코드 생성
    private func generateBasicInfoQRCode() async {
        let basicInfo = CategoryBasicInfo(from: self.category)
        
        guard let jsonData = try? JSONEncoder().encode(basicInfo) else {
            await MainActor.run {
                self.errorMessage = "qr_encode_failed".localized
            }
            return
        }
        
        // 데이터 압축
        guard let compressedData = try? (jsonData as NSData).compressed(using: .zlib) as Data else {
            await MainActor.run {
                self.errorMessage = "qr_encode_failed".localized
            }
            return
        }
        
        let base64String = compressedData.base64EncodedString()
        
        // 데이터 크기 체크
        if base64String.count > self.maxDataSize {
            await MainActor.run {
                self.errorMessage = "qr_code_too_large".localized
            }
            return
        }
        
        // QR 코드 생성
        if let qrImage = await self.generateQRImage(from: base64String) {
            await MainActor.run {
                self.basicInfoQRImage = qrImage
            }
        }
    }
    
    /// 카운팅 데이터 QR 코드 생성
    private func generateCountingDataQRCode() async {
        let countingData = CategoryCountingData(from: self.category)
        
        guard let jsonData = try? JSONEncoder().encode(countingData) else {
            await MainActor.run {
                self.errorMessage = "qr_encode_failed".localized
            }
            return
        }
        
        // 데이터 압축
        guard let compressedData = try? (jsonData as NSData).compressed(using: .zlib) as Data else {
            await MainActor.run {
                self.errorMessage = "qr_encode_failed".localized
            }
            return
        }
        
        let base64String = compressedData.base64EncodedString()
        
        // 데이터 크기 체크
        if base64String.count > self.maxDataSize {
            await MainActor.run {
                self.errorMessage = "qr_code_too_large".localized
            }
            return
        }
        
        // QR 코드 생성
        if let qrImage = await self.generateQRImage(from: base64String) {
            await MainActor.run {
                self.countingDataQRImage = qrImage
            }
        }
    }
    
    /// QR 이미지 생성 헬퍼
    private func generateQRImage(from string: String) async -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let transform = CGAffineTransform(scaleX: self.qrScale, y: self.qrScale)
        let scaledImage = outputImage.transformed(by: transform)
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}
