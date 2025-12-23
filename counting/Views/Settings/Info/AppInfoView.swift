//
//  AppInfoView.swift
//  counting
//
//  Created by MARKLIM on 2025-12-21.
//
//  앱 정보 및 오픈소스 라이선스 고지 화면
//

import SwiftUI

struct AppInfoView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // 앱 아이콘 및 이름
                VStack(spacing: 16) {
                    Text("My Counting")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("\("version".localized) \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                
                Divider()
                
                // 오픈소스 라이선스 섹션 (QR 코드)
                VStack(alignment: .leading, spacing: 10) {
                    Text("trademark_notice".localized)
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("QR Code")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("qr_code_license_desc".localized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        // 추가적인 라이브러리나 출처가 있다면 여기에 추가
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Footer
                Text("Created by MarkLim")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 20)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("app_info".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AppInfoView()
        }
    }
}
