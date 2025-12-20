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
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        NavigationView {
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
                            .foregroundColor(.primary)
                        
                        Text(category.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("qr_scan_instruction".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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
                            .frame(width: 250, height: 250)
                            .padding(30)
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: category.color.opacity(0.3), radius: 20, x: 0, y: 10)
                    } else {
                        VStack(spacing: 15) {
                            ProgressView()
                                .scaleEffect(1.5)
                            
                            Text("generating_qr_code".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 250, height: 250)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(24)
                    }
                    
                    // 카테고리 정보
                    VStack(spacing: 8) {
                        HStack {
                            Text("counter_count".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(category.counters.count)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
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
        // 전체 카테고리 데이터 포함 (카운터 데이터 포함)
        guard let jsonData = try? JSONEncoder().encode(category),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        
        // QR 코드 생성
        filter.message = Data(jsonString.utf8)
        
        // 에러 보정 레벨을 낮춰서 QR 코드 복잡도 감소
        filter.setValue("L", forKey: "inputCorrectionLevel") // L = 7% 에러 보정 (가장 낮음)
        
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                qrCodeImage = UIImage(cgImage: cgImage)
            }
        }
    }
}
