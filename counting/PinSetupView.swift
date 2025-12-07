
import SwiftUI

struct PinSetupView: View {
    @Binding var isPresented: Bool
    @Binding var isLockEnabled: Bool
    
    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var isConfirming = false
    @State private var message = "암호 4자리를 입력하세요"
    @State private var isError = false
    
    // 흔들림 애니메이션을 위한 상태
    @State private var shakeOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
            
            VStack {
                // 헤더: 취소 버튼
                HStack {
                    Button("취소") {
                        isLockEnabled = false // 취소하면 잠금 활성화 실패
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                    .padding()
                    Spacer()
                }
                
                Spacer()
                
                VStack(spacing: 20) {
                    // 상단 아이콘
                    Image(systemName: isError ? "lock.open.fill" : "lock.fill")
                        .font(.system(size: 40))
                        .foregroundColor(isError ? .red : .blue)
                        .padding(.bottom, 10)
                    
                    Text(message)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(isError ? .red : .primary)
                    
                    // PIN 입력 상태 표시 (동그라미 4개)
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
                    .modifier(ShakeEffect(offset: shakeOffset)) // 애니메이션 적용
                }
                
                Spacer()
                
                // 숫자 키패드
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    ForEach(1...9, id: \.self) { number in
                        NumberButton(number: "\(number)") {
                            handleInput("\(number)")
                        }
                    }
                    // 빈 공간
                    Color.clear
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
    
    // 동그라미 색상 결정
    func getDotColor(index: Int) -> Color {
        let currentPin = isConfirming ? confirmPin : pin
        if isError { return .red }
        return index < currentPin.count ? .primary : .clear
    }
    
    // 숫자 입력 처리
    func handleInput(_ number: String) {
        if isError { resetError() }
        
        if isConfirming {
            if confirmPin.count < 4 {
                confirmPin.append(number)
                if confirmPin.count == 4 {
                    validatePin()
                }
            }
        } else {
            if pin.count < 4 {
                pin.append(number)
                if pin.count == 4 {
                    // 1차 입력 완료 -> 2차 확인 모드로 전환
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        guard pin.count == 4 else { return }
                        isConfirming = true
                        message = "암호를 다시 한 번 입력하세요"
                    }
                }
            }
        }
    }
    
    // 지우기 처리
    func handleDelete() {
        if isError { resetError(); return }
        
        if isConfirming {
            if !confirmPin.isEmpty { confirmPin.removeLast() }
            else {
                // 확인 모드에서 다 지우면 -> 다시 1차 입력 모드로? (선택사항, 보통 유지)
                // 여기서는 확인 모드 유지
            }
        } else {
            if !pin.isEmpty { pin.removeLast() }
        }
    }
    
    // PIN 검증
    func validatePin() {
        if pin == confirmPin {
            // 일치: 저장 시도
            if KeychainHelper.shared.savePin(pin) {
                // 저장 성공
                isLockEnabled = true
                isPresented = false
            } else {
                // 저장 실패 (Keychain 에러)
                isError = true
                message = "암호 저장에 실패했습니다. 다시 시도해주세요."
                triggerShake()
            }
        } else {
            // 불일치: 에러 표시
            isError = true
            message = "비밀번호가 일치하지 않습니다"
            triggerShake()
            
            // 잠시 후 리셋 (처음부터 다시)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                resetToStart()
            }
        }
    }
    
    func resetError() {
        isError = false
        message = isConfirming ? "암호를 다시 한 번 입력하세요" : "암호 4자리를 입력하세요"
    }
    
    func resetToStart() {
        pin = ""
        confirmPin = ""
        isConfirming = false
        isError = false
        message = "암호 4자리를 입력하세요"
    }
    
    func triggerShake() {
        withAnimation(.default) {
            shakeOffset = 10
        }
        withAnimation(Animation.default.repeatCount(3, autoreverses: true).speed(4)) {
            shakeOffset = 0
        }
    }
}

// 키패드 버튼
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

// 흔들림 효과 Modifier
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
