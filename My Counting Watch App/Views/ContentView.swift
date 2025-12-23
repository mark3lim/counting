
//
//  ContentView.swift
//  My Counting Watch App
//
//  Created by MARKLIM on 2025-12-07.
//
//  Watch 앱의 메인 화면입니다.

//  NavigationStack을 사용하여 카테고리 상세 화면으로 이동을 관리합니다.
//

import SwiftUI
import Observation

struct ContentView: View {
    // 앱 전체 상태 관리 (카테고리 및 동기화)
    @StateObject private var appState = AppState()
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // 헤더 영역
                    HStack {
                        Text("my_counters".localized)
                            .font(.headline)
                            .foregroundStyle(.orange)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                    
                    ScrollView {
                        VStack(spacing: 8) {
                            // 카테고리가 없는 경우 안내 문구 표시
                            if appState.categories.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "archivebox")
                                        .font(.largeTitle)
                                        .foregroundStyle(.gray)
                                    Text("No Categories")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                .padding(.vertical, 20)
                            } else {
                                // 카테고리 목록 표시
                                ForEach(appState.categories) { category in
                                    NavigationLink(destination: CategoryView(categoryId: category.id)) {
                                        HStack {
                                            // 아이콘/색상 점
                                            Circle()
                                                .fill(category.color)
                                                .frame(width: 10, height: 10)
                                            
                                            // 카테고리 이름
                                            Text(category.name)
                                                .font(.system(size: 14, weight: .medium))
                                                .lineLimit(1)
                                            
                                            Spacer()
                                            
                                            // 카테고리 내 모든 카운터 합계 표시
                                            let total = category.counters.reduce(0) { $0 + $1.count }
                                            let displayString = total.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", total) : String(format: "%.1f", total)
                                            
                                            Text(displayString)
                                                .font(.system(size: 13, design: .monospaced))
                                                .foregroundStyle(.gray)
                                        }
                                        .padding()
                                        .frame(height: 48)
                                        .background(Color(white: 0.1)) // 다크 모드 배경
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                        }
                        .padding(.horizontal, 4)
                        .padding(.bottom)
                    }
                }
                
                if appState.isLoading {
                    ProgressView()
                        .tint(.orange)
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.5))
                        .ignoresSafeArea()
                }
            }
            .background(Color.black)
        }
        .environmentObject(appState)
    }
}

#Preview {
    ContentView()
}
