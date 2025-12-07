
//
//  CounterView.swift
//  My Counting Watch App
//
//  Created by MARKLIM on 2025-12-07.
//
//  카운터 상세 화면입니다.
//  탭하여 숫자를 증가시키거나, 하단 버튼으로 감소/초기화 할 수 있습니다.
//

import SwiftUI

struct CounterView: View {
    // 카운터 데이터 바인딩
    @Binding var counter: TallyCounter
    let color: Color
    
    // 애니메이션 및 알림 상태
    @State private var scale: CGFloat = 1.0
    @State private var showingResetAlert = false
    
    var body: some View {
        ZStack {
            // 배경 / 전체 터치 영역
            Color.black.ignoresSafeArea()
            
            VStack {
                // 상단: 카운터 이름
                Text(counter.name)
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
                    .lineLimit(1)
                    .padding(.top, 2)
                
                Spacer()
                
                // 중앙: 큰 숫자 표시
                let displayString = counter.count.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", counter.count) : String(format: "%.1f", counter.count)
                
                Text(displayString)
                    .font(.system(size: 60, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
                    .scaleEffect(scale) // 탭 시 커지는 애니메이션 효과
                    .shadow(radius: 5)
                    .onTapGesture {
                        increment()
                    }
                
                // 탭 안내 문구
                Text("TAP TO COUNT")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Capsule())
                    .padding(.top, 4)
                    .allowsHitTesting(false) // 터치 이벤트를 배경으로 전달
                
                Spacer()
                
                // 하단 컨트롤: 초기화 및 감소 버튼
                HStack {
                    // 초기화 버튼
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.red)
                            .frame(width: 40, height: 40)
                            .background(Color.red.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // 감소 버튼
                    Button(action: {
                        decrement()
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.gray)
                            .frame(width: 40, height: 40)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
        }
        .contentShape(Rectangle()) // 빈 영역도 터치 가능하도록 설정
        .onTapGesture {
            increment()
        }
        // 초기화 확인 알림
        .alert("카운터 초기화", isPresented: $showingResetAlert) {
            Button("취소", role: .cancel) { }
            Button("초기화", role: .destructive) {
                counter.count = 0
            }
        } message: {
            Text("정말 0으로 초기화하시겠습니까?")
        }
    }
    
    // 카운트 증가 및 애니메이션
    private func increment() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            scale = 1.2
        }
        counter.count += 1
        
        // 애니메이션 복귀
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                scale = 1.0
            }
        }
    }
    
    // 카운트 감소 (0 미만 방지 로직 포함)
    private func decrement() {
        if counter.count >= 1 {
            counter.count -= 1
        } else if counter.count > 0 {
            counter.count = 0
        }
    }
}
