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

struct CategoryQRCodeView: View {
    let category: TallyCategory
    
    @Environment(\.dismiss) var dismiss
    @State private var qrImage: UIImage?
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
                    
                    // QR 코드 카드
                    qrCodeCard
                    
                    // 설명 카드
                    descriptionCard
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(category.name)
        .onAppear {
            Task {
                await generateQRCode()
            }
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
    
    /// QR 코드 카드
    private var qrCodeCard: some View {
        VStack(spacing: 20) {
            if let qrImage = qrImage {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: qrSize, height: qrSize)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            } else if let errorMessage = errorMessage {
                errorView(message: errorMessage)
            } else {
                loadingView
            }
            
            // QR Code Label
            Text("qr_scan_guide".localized)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.5), lineWidth: 1)
                )
        }
    }
    
    /// 설명 카드
    private var descriptionCard: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "info.circle.fill")
                .font(.title2)
                .foregroundStyle(category.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(String(format: "%d개 카운터 포함", category.counters.count))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
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
    
    /// QR 코드 생성
    private func generateQRCode() async {
        let data = CategoryData(from: self.category)
        
        guard let jsonData = try? JSONEncoder().encode(data) else {
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
        
        // 데이터 크기 체크 (보수적으로 3000자 제한)
        if base64String.count > 3000 {
            await MainActor.run {
                self.errorMessage = "qr_code_too_large".localized
            }
            return
        }
        
        // QR 코드 생성
        if let qrImage = await self.generateQRImage(from: base64String) {
            await MainActor.run {
                self.qrImage = qrImage
            }
        }
    }
    
    /// QR 이미지 생성 헬퍼
    private func generateQRImage(from string: String) async -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        filter.setValue("Q", forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let transform = CGAffineTransform(scaleX: self.qrScale, y: self.qrScale)
        let scaledImage = outputImage.transformed(by: transform)
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}
