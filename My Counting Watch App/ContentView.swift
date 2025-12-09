
//
//  ContentView.swift
//  My Counting Watch App
//
//  Created by MARKLIM on 2025-12-07.
//
//  Watch 앱의 메인 화면입니다.
//  카테고리 목록을 표시하며, 데이터가 없을 경우 iPhone 앱에서 추가하라는 안내를 보여줍니다.
//  NavigationStack을 사용하여 카테고리 상세 화면으로 이동을 관리합니다.
//

import SwiftUI
import Observation

struct ContentView: View {
    // 앱 전체 상태 관리 (카테고리 및 동기화)
    @State private var appState = AppState()
    
    // 동기화 실패 알림 상태
    @State private var showingSyncError = false
    
    var body: some View {
        @Bindable var bindableAppState = appState
        
        NavigationStack {
            VStack(spacing: 0) {
                // 헤더 영역
                HStack {
                    Text("my_counters".localized)
                        .font(.headline)
                        .foregroundStyle(.orange)
                    Spacer()
                    
                    if bindableAppState.isSyncing {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 20, height: 20)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
                
                ScrollView {
                    VStack(spacing: 8) {
                        // 카테고리가 없는 경우 안내 문구 표시
                        if bindableAppState.categories.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "iphone.gen3")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.gray)
                                Text("watch_add_on_iphone".localized)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 20)
                        } else {
                            // 카테고리 목록 표시
                            ForEach($bindableAppState.categories) { $category in
                                NavigationLink(destination: CategoryView(category: $category)) {
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
                        
                        // 동기화 버튼 (아이폰에서 데이터 가져오기)
                        Button(action: {
                            guard !appState.isSyncing else { return }
                            
                            // 동기화 시작 (UI 상태 변경)
                            withAnimation {
                                appState.isSyncing = true
                            }
                            
                            // 강제 데이터 요청
                            ConnectivityProvider.shared.requestData()
                            
                            // 타임아웃 처리 (5초 내 응답 없으면 에러 표시)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                if appState.isSyncing {
                                    withAnimation {
                                        appState.isSyncing = false
                                    }
                                    showingSyncError = true
                                }
                            }
                        }) {
                            HStack(spacing: 6) {
                                if appState.isSyncing {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                        .frame(width: 20, height: 20)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                }
                                
                                Text("sync_now".localized)
                                    .font(.system(size: 14))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(appState.isSyncing ? Color.gray.opacity(0.3) : Color.blue.opacity(0.3))
                            .foregroundStyle(appState.isSyncing ? .gray : .blue)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(appState.isSyncing)
                        .padding(.top, 4)
                        .alert("error".localized, isPresented: $showingSyncError) {
                            Button("confirm".localized, role: .cancel) { }
                        } message: {
                            Text("sync_error_message".localized)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom)
                }
            }
            .background(Color.black)
        }
    }
}

#Preview {
    ContentView()
}
