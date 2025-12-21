
//
//  LockView.swift
//  counting
//
//  Created by MARKLIM on 2025-12-07.
//
//  앱 잠금 화면 뷰입니다.
//  PIN 번호 입력 및 Face ID 인증을 통해 앱 잠금을 해제하는 기능을 제공합니다.
//

import SwiftUI
import LocalAuthentication

struct LockView: View {
    // 잠금 상태 바인딩 (이제 LockManager에서 관리하지만, 유연성을 위해 바인딩 유지)
    @Binding var isLocked: Bool
    @ObservedObject var lockManager = LockManager.shared
    
    @ObservedObject var l10n = LocalizationManager.shared
    
    // 입력 상태 관리
    @State private var pin: String = ""
    @State private var isError: Bool = false
    @State private var shakeOffset: CGFloat = 0
    @State private var message: String = "enter_password".localized
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        ZStack {
            // 배경색 (시스템 배경)
            Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                // 잠금 아이콘 및 메시지 영역
                VStack(spacing: 20) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                        .padding(.bottom, 10)
                    
                    Text(message)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(isError ? .red : .primary)
                    
                    // PIN 입력 상태 인디케이터
                    HStack(spacing: 20) {
                        ForEach(0..<4) { index in
                            Circle()
                                .fill(index < pin.count ? Color.primary : Color.clear)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Circle()
                                        .stroke(isError ? Color.red : Color.primary, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.vertical, 30)
                    .modifier(ShakeEffect(offset: shakeOffset)) // 에러 시 흔들림 효과
                }
                
                Spacer()
                
                // 숫자 키패드 및 Face ID 버튼
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    ForEach(1...9, id: \.self) { number in
                        NumberButton(number: "\(number)") {
                            handleInput("\(number)")
                        }
                    }
                    
                    // Face ID 버튼 (설정된 경우에만 표시)
                    if lockManager.useFaceID {
                        Button(action: {
                            lockManager.authenticate()
                        }) {
                            Image(systemName: "faceid")
                                .font(.title)
                                .foregroundColor(.primary)
                                .frame(width: 70, height: 70)
                        }
                    } else {
                        Color.clear // 자리 채움용 빈 뷰
                    }
                    
                    NumberButton(number: "0") {
                        handleInput("0")
                    }
                    
                    // 지우기 버튼
                    Button(action: handleDelete) {
                        Image(systemName: "delete.left.fill")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .frame(width: 70, height: 70)
                    }
                }
                .padding(.bottom, 40)
                .padding(.horizontal, 40)
            }
        }
        // Face ID 인증 로직 통합 (초기 진입 및 포그라운드 복귀 모두 처리)
        // .onChange 및 .onAppear에서의 자동 인증 제거
        // 문제 해결: 화면 전환 시 불필요한 인증 시도 방지.
        // LockManager에서 필요한 시점에 authenticate()를 호출하도록 하거나,
        // 사용자가 명시적으로 Face ID 버튼을 누르도록 유도.
        // UX 유지를 위해 onAppear에서 "잠겨있을 때만" 한번 시도하는 것은 유지하되,
        // scene Phase 변화에 따른 중복 트리거는 제거.
        .onAppear {
             message = "enter_password".localized
        }
        .onChange(of: lockManager.isLocked) { _, newValue in
            isLocked = newValue
        }
    }
    
    // 키패드 입력 처리
    func handleInput(_ number: String) {
        if isError {
            isError = false
            message = "enter_password".localized
        }
        
        if pin.count < 4 {
            pin.append(number)
            if pin.count == 4 {
                validatePin() // 4자리 입력 시 검증
            }
        }
    }
    
    // 지우기 버튼 처리
    func handleDelete() {
        if isError {
            isError = false
            message = "enter_password".localized
            pin = ""
            return
        }
        if !pin.isEmpty { pin.removeLast() }
    }
    
    // PIN 검증 로직
    func validatePin() {
        if lockManager.validatePin(pin) {
            lockManager.unlock()
        } else {
            showError()
        }
    }
    
    // 에러 표시 및 애니메이션
    func showError() {
        isError = true
        message = "password_mismatch".localized
        withAnimation(.default) {
            shakeOffset = 10
        }
        withAnimation(Animation.default.repeatCount(3, autoreverses: true).speed(4)) {
            shakeOffset = 0
        }
        
        // 잠시 후 입력 초기화
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            pin = ""
            isError = false
            message = "enter_password".localized
        }
    }
}
