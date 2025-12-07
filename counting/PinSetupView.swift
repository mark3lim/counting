
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
    @Binding var isPresented: Bool
    @Binding var isLockEnabled: Bool
    
    @ObservedObject var l10n = LocalizationManager.shared
    
    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var isConfirming = false
    @State private var message = "enter_pin_4".localized
    @State private var isError = false
    @State private var shakeOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Button("cancel".localized) {
                        isLockEnabled = false
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                    .padding()
                    Spacer()
                }
                
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: isError ? "lock.open.fill" : "lock.fill")
                        .font(.system(size: 40))
                        .foregroundColor(isError ? .red : .blue)
                        .padding(.bottom, 10)
                    
                    Text(message)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(isError ? .red : .primary)
                    
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
                    .modifier(ShakeEffect(offset: shakeOffset))
                }
                
                Spacer()
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    ForEach(1...9, id: \.self) { number in
                        NumberButton(number: "\(number)") {
                            handleInput("\(number)")
                        }
                    }
                    Color.clear
                    NumberButton(number: "0") {
                        handleInput("0")
                    }
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
    
    func getDotColor(index: Int) -> Color {
        let currentPin = isConfirming ? confirmPin : pin
        if isError { return .red }
        return index < currentPin.count ? .primary : .clear
    }

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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        guard pin.count == 4 else { return }
                        isConfirming = true
                        message = "enter_pin_again".localized
                    }
                }
            }
        }
    }
    
    func handleDelete() {
        if isError { resetError(); return }
        if isConfirming {
            if !confirmPin.isEmpty { confirmPin.removeLast() }
        } else {
            if !pin.isEmpty { pin.removeLast() }
        }
    }
    
    func validatePin() {
        if pin == confirmPin {
            if KeychainHelper.shared.savePin(pin) {
                isLockEnabled = true
                isPresented = false
            } else {
                isError = true
                message = "pin_save_error".localized
                triggerShake()
            }
        } else {
            isError = true
            message = "pin_mismatch".localized
            triggerShake()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                resetToStart()
            }
        }
    }
    
    func resetError() {
        isError = false
        message = isConfirming ? "enter_pin_again".localized : "enter_pin_4".localized
    }
    
    func resetToStart() {
        pin = ""
        confirmPin = ""
        isConfirming = false
        isError = false
        message = "enter_pin_4".localized
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


