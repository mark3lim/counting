
//
//  UIComponents.swift
//  counting
//
//  Created by MARKLIM on 2025-12-07.
//
//  앱 전반에서 공통으로 사용되는 UI 컴포넌트들을 정의합니다.
//

import SwiftUI

// 키패드 숫자 버튼 컴포넌트
struct NumberButton: View {
    let number: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.title)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .frame(width: 70, height: 70)
                .background(Color(.systemGray6))
                .clipShape(Circle())
        }
    }
}

// 흔들림 효과(Shake Animation)
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
