//
//  QRCodeScannerView.swift
//  counting
//
//  Created by MARKLIM on 2025-12-20.
//
//  QR 코드를 스캔하여 카테고리 데이터를 가져오는 뷰
//

import SwiftUI
import AVFoundation

struct QRCodeScannerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: TallyStore
    
    @State private var showingImportAlert = false
    @State private var importedCategory: TallyCategory?
    
    var body: some View {
        NavigationView {
            ZStack {
                // QR 스캐너 (실제 구현 시 AVFoundation 사용)
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // 스캔 가이드
                    VStack(spacing: 16) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        Text("qr_scan_guide".localized)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("qr_scan_description".localized)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                    
                    // 테스트용 버튼 (실제 스캔 기능 구현 전)
                    Button {
                        // 테스트용 더미 데이터
                        testImport()
                    } label: {
                        Text("테스트 가져오기")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(16)
                    }
                    .padding(.bottom, 40)
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
                            .foregroundColor(.white)
                    }
                }
            }
            .alert("import_category_title".localized, isPresented: $showingImportAlert) {
                Button("import".localized) {
                    if let category = importedCategory {
                        importCategory(category)
                    }
                }
                Button("cancel".localized, role: .cancel) { }
            } message: {
                if let category = importedCategory {
                    Text(String(format: "import_category_message".localized, category.name))
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func testImport() {
        // 테스트용 더미 카테고리 생성
        let testCategory = TallyCategory(
            name: "테스트 카테고리",
            colorName: "bg-blue-600",
            iconName: "star.fill",
            counters: [],
            allowNegative: false,
            allowDecimals: false
        )
        
        importedCategory = testCategory
        showingImportAlert = true
    }
    
    private func importCategory(_ category: TallyCategory) {
        // 카테고리 가져오기 (전체 데이터 포함)
        store.importCategory(category)
        
        dismiss()
    }
}
