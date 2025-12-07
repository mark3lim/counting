
//
//  PinSetupView.swift
//  counting
//
//  Created by MARKLIM on 2025-12-07.
//
//  PIN 번호 설정 화면입니다.
//  새로운 PIN 번호를 입력하고 확인하는 과정을 처리합니다.
//

import SwiftUI

struct PinSetupView: View {
    // 뷰 표시 여부 및 잠금 활성화 상태 바인딩
    @Binding var isPresented: Bool
    @Binding var isLockEnabled: Bool
    
    // 입력 상태 관리 변수들
    @State private var pin = "" // 첫 번째 입력한 PIN
    @State private var confirmPin = "" // 확인을 위해 두 번째 입력한 PIN
    @State private var isConfirming = false // 확인 단계 진입 여부
    @State private var message = "암호 4자리를 입력하세요" // 안내 메시지
    @State private var isError = false // 에러 발생 여부
    
    // 흔들림 애니메이션을 위한 오프셋 상태
    @State private var shakeOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // 배경색 설정
            Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
            
            VStack {
                // 헤더 영역: 취소 버튼 포함
                HStack {
                    Button("취소") {
                        isLockEnabled = false // 취소 시 잠금 활성화 실패 처리
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                    .padding()
                    Spacer()
                }
                
                Spacer()
                
                // 안내 메시지 및 인디케이터 영역
                VStack(spacing: 20) {
                    // 상단 아이콘 (에러 시 잠금 해제 아이콘 표시)
                    Image(systemName: isError ? "lock.open.fill" : "lock.fill")
                        .font(.system(size: 40))
                        .foregroundColor(isError ? .red : .blue)
                        .padding(.bottom, 10)
                    
                    // 안내 텍스트
                    Text(message)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(isError ? .red : .primary)
                    
                    // PIN 입력 상태 인디케이터 (동그라미 4개)
                    HStack(spacing: 20) {
                        ForEach(0..<4) { index in
                            Circle()
                                .fill(getDotColor(index: index))
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Circle()
                                        .stroke(isError ? Color.red : Color.primary, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.vertical, 30)
                    .modifier(ShakeEffect(offset: shakeOffset)) // 에러 시 흔들림 효과 적용
                }
                
                Spacer()
                
                // 커스텀 숫자 키패드
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    ForEach(1...9, id: \.self) { number in
                        NumberButton(number: "\(number)") {
                            handleInput("\(number)")
                        }
                    }
                    // 빈 공간 (키패드 정렬용)
                    Color.clear
                    // 0번 버튼
                    NumberButton(number: "0") {
                        handleInput("0")
                    }
                    // 지우기 버튼
                    Button(action: {
                        handleDelete()
                    }) {
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
    }
    
    // 인디케이터 동그라미의 색상을 결정하는 함수
    func getDotColor(index: Int) -> Color {
        let currentPin = isConfirming ? confirmPin : pin
        if isError { return .red } // 에러 상태일 때는 빨간색
        return index < currentPin.count ? .primary : .clear // 입력된 자릿수만큼 채움
    }
    
    // 숫자 입력 처리 함수
    func handleInput(_ number: String) {
        if isError { resetError() } // 에러 상태였다면 초기화
        
        if isConfirming {
            // 2차 확인 단계
            if confirmPin.count < 4 {
                confirmPin.append(number)
                if confirmPin.count == 4 {
                    validatePin() // 4자리 입력 완료 시 검증
                }
            }
        } else {
            // 1차 입력 단계
            if pin.count < 4 {
                pin.append(number)
                if pin.count == 4 {
                    // 1차 입력 완료 후 잠시 대기하다가 확인 모드로 전환
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        guard pin.count == 4 else { return }
                        isConfirming = true
                        message = "암호를 다시 한 번 입력하세요"
                    }
                }
            }
        }
    }
    
    // 지우기 버튼 처리 함수
    func handleDelete() {
        if isError { resetError(); return }
        
        if isConfirming {
            if !confirmPin.isEmpty { confirmPin.removeLast() }
        } else {
            if !pin.isEmpty { pin.removeLast() }
        }
    }
    
    // 입력된 PIN 검증 및 저장 함수
    func validatePin() {
        if pin == confirmPin {
            // 핀 번호가 일치하면 Keychain에 저장 시도
            if KeychainHelper.shared.savePin(pin) {
                // 저장 성공
                isLockEnabled = true
                isPresented = false
            } else {
                // 저장 실패 처리
                isError = true
                message = "암호 저장에 실패했습니다. 다시 시도해주세요."
                triggerShake()
            }
        } else {
            // 핀 번호 불일치 처리
            isError = true
            message = "비밀번호가 일치하지 않습니다"
            triggerShake()
            
            // 잠시 후 초기 상태로 리셋
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                resetToStart()
            }
        }
    }
    
    // 에러 상태 리셋
    func resetError() {
        isError = false
        message = isConfirming ? "암호를 다시 한 번 입력하세요" : "암호 4자리를 입력하세요"
    }
    
    // 입력 초기화 (처음부터 다시)
    func resetToStart() {
        pin = ""
        confirmPin = ""
        isConfirming = false
        isError = false
        message = "암호 4자리를 입력하세요"
    }
    
    // 흔들림 애니메이션 트리거
    func triggerShake() {
        withAnimation(.default) {
            shakeOffset = 10
        }
        withAnimation(Animation.default.repeatCount(3, autoreverses: true).speed(4)) {
            shakeOffset = 0
        }
    }
}

// 키패드 숫자 버튼 컴포넌트
struct NumberButton: View {
    let number: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.title)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(width: 70, height: 70)
                .background(Color(.systemGray6))
                .clipShape(Circle())
        }
    }
}

// 흔들림 효과(Shake Animation) 구현을 위한 GeometryEffect
struct ShakeEffect: GeometryEffect {
    var offset: CGFloat
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

#Preview {
    PinSetupView(isPresented: .constant(true), isLockEnabled: .constant(false))
}
