
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
    
    // 추가 버튼 눌렀을 때 표시할 알림 상태
    @State private var showingAddAlert = false
    
    var body: some View {
        @Bindable var bindableAppState = appState
        
        NavigationStack {
            VStack(spacing: 0) {
                // 헤더 영역
                HStack {
                    Text("나의 카운터")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    Spacer()
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
                                Text("아이폰 앱에서\n카테고리를 추가해주세요.")
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
                        
                        // 추가 버튼 (Watch에서는 직접 추가 불가, iPhone 안내)
                        Button(action: {
                            showingAddAlert = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color.gray.opacity(0.2))
                            .foregroundStyle(.gray)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom)
                }
            }
            .background(Color.black)
            .alert("알림", isPresented: $showingAddAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("아이폰 앱에서 추가해주세요.")
            }
        }
    }
}

#Preview {
    ContentView()
}
