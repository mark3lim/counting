//
//  CategoryQRCodeView.swift
//  counting
//
//  Created by MARKLIM on 2025-12-20.
//
//  카테고리 데이터를 QR 코드로 표시하는 뷰
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct CategoryQRCodeView: View {
    let category: TallyCategory
    
    @Environment(\.dismiss) var dismiss
    @State private var qrCodeImage: UIImage?
    @State private var errorMessage: String?
    
    // Constants
    private let qrScale: CGFloat = 10.0
    private let qrSize: CGFloat = 250.0
    private let maxDataSize = 2500 // QR code capacity limit (approx bytes for L correction)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 배경 - 카테고리 색상 그라데이션
                LinearGradient(
                    colors: [
                        category.color.opacity(0.3),
                        category.color.opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    // 헤더
                    VStack(spacing: 12) {
                        Image(systemName: category.icon)
                            .font(.system(size: 50))
                            .foregroundStyle(.primary)
                        
                        Text(category.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text("qr_scan_instruction".localized)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 20)
                    
                    // QR 코드
                    if let qrImage = qrCodeImage {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: qrSize, height: qrSize)
                            .padding(30)
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: category.color.opacity(0.3), radius: 20, x: 0, y: 10)
                    } else if let error = errorMessage {
                         // 에러 표시
                        VStack(spacing: 15) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundStyle(.orange)
                            
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(width: qrSize, height: qrSize)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(24)
                    } else {
                        // 로딩 표시
                        VStack(spacing: 15) {
                            ProgressView()
                                .scaleEffect(1.5)
                            
                            Text("generating_qr_code".localized)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: qrSize, height: qrSize)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(24)
                    }
                    
                    // 카테고리 정보
                    VStack(spacing: 8) {
                        HStack {
                            Text("counter_count".localized)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(category.counters.count)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(16)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .onAppear {
                generateQRCode()
            }
        }
    }
    
    // MARK: - Methods
    
    private func generateQRCode() {
        // 카테고리 데이터를 미리 캡처 (MainActor에서)
        let categoryToEncode = self.category
        
        // UI 블로킹 방지를 위해 백그라운드 스레드에서 수행
        Task.detached(priority: .userInitiated) {
            // 전체 카테고리 데이터 포함
            guard let jsonData = try? JSONEncoder().encode(categoryToEncode) else {
                await MainActor.run {
                    self.errorMessage = "qr_encode_failed".localized
                }
                return
            }
            
            // 데이터 압축 (zlib) - iOS 13+ 표준 API 사용 (Android 호환성 좋음)
            // JSON -> Compressed Data -> Base64 String
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
            
            // CoreImage Context 로컬 생성
            let context = CIContext()
            let filter = CIFilter.qrCodeGenerator()
            
            // QR 코드 생성
            filter.message = Data(base64String.utf8)
            
            // 에러 보정 레벨
            filter.setValue("L", forKey: "inputCorrectionLevel")
            
            if let outputImage = filter.outputImage {
                let transform = CGAffineTransform(scaleX: self.qrScale, y: self.qrScale)
                let scaledImage = outputImage.transformed(by: transform)
                
                if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                    let uiImage = UIImage(cgImage: cgImage)
                    
                    // UI 업데이트는 메인 스레드에서
                    await MainActor.run {
                        self.qrCodeImage = uiImage
                    }
                }
            }
        }
    }
}
