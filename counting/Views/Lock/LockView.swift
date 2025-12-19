
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
    // 잠금 상태 바인딩 (true: 잠김, false: 해제)
    @Binding var isLocked: Bool
    
    @ObservedObject var l10n = LocalizationManager.shared
    
    // 입력 상태 관리
    @State private var pin: String = ""
    @State private var isError: Bool = false
    @State private var shakeOffset: CGFloat = 0
    @State private var message: String = "enter_password".localized
    
    // Face ID 사용 설정 (UserDefaults)
    @AppStorage("useFaceID") private var useFaceID = false
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
                    if useFaceID {
                        Button(action: authenticate) {
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
        // 뷰가 나타날 때 Face ID가 활성화되어 있으면 즉시 인증 시도
        .onAppear {
            message = "enter_password".localized // 언어 변경 대응
            if useFaceID {
                authenticate()
            }
        }
        // 백그라운드에서 포그라운드로 복귀 시 Face ID 자동 실행
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if oldPhase == .background && newPhase == .active {
                if useFaceID && isLocked {
                    authenticate()
                }
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
        // Keychain에서 저장된 PIN 로드
        guard let storedPin = KeychainHelper.shared.readPin() else {
            showError()
            return
        }
        
        // 상수 시간 비교(Constant-time comparison)를 사용하여 타이밍 공격 방지
        if constantTimeCompare(storedPin, pin) {
            unlock()
        } else {
            showError()
        }
    }
    
    // 타이밍 공격 방지를 위한 상수 시간 문자열 비교 함수
    private func constantTimeCompare(_ lhs: String, _ rhs: String) -> Bool {
        let lhsData = Array(lhs.utf8)
        let rhsData = Array(rhs.utf8)
        
        // 길이가 다르면 즉시 false 반환 (PIN은 4자리로 고정되어 있어 길이 정보 노출은 치명적이지 않음)
        guard lhsData.count == rhsData.count else { return false }
        
        var result: UInt8 = 0
        for i in 0..<lhsData.count {
            // XOR 연산을 통해 차이 누적 (차이가 하나라도 있으면 result는 0이 아님)
            result |= lhsData[i] ^ rhsData[i]
        }
        
        return result == 0
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
    
    // 잠금 해제
    func unlock() {
        withAnimation {
            isLocked = false
        }
    }
    
    // 생체 인증(Face ID/Touch ID) 시도
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "unlock_reason".localized
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        unlock()
                    } else {
                        // 인증 실패 또는 취소 시 PIN 입력 화면 유지
                    }
                }
            }
        }
    }
}


