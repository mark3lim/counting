
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
        .onChange(of: scenePhase, initial: true) { _, newPhase in
            if newPhase == .active {
                // LockManager가 상태를 확인하고 인증을 시작합니다.
                lockManager.authenticate()
            }
        }
        // LockManager의 잠금 상태 변화를 감지하여 뷰를 닫거나 처리 (바인딩이 있어 자동 처리될 수도 있지만 명시적 동기화)
        .onChange(of: lockManager.isLocked) { _, newValue in
            isLocked = newValue
        }
        .onAppear {
            message = "enter_password".localized
            // 뷰가 나타날 때, 앱이 활성 상태인 경우에만 인증 시도
            // (앱 전환기나 알림 센터 등으로 인해 비활성 상태에서 잠길 때는 인증을 요청하지 않음)
            if scenePhase == .active {
                lockManager.authenticate()
            }
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
