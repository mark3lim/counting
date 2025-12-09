
//
//  CategoryView.swift
//  My Counting Watch App
//
//  Created by MARKLIM on 2025-12-07.
//
//  카테고리 상세 화면입니다.
//  해당 카테고리에 포함된 카운터 목록을 표시하고, 선택 시 카운터 상세 화면으로 이동합니다.
//

import SwiftUI

struct CategoryView: View {
    // 선택된 카테고리 바인딩
    @Binding var category: TallyCategory
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if category.counters.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 24))
                            .foregroundStyle(.gray)
                            .padding(.top, 20)
                        
                        Text("no_counters".localized) // Localizable 키가 없다면 "등록된 카운터가 없습니다."로 대체 필요하나, 일단 키 사용 시도 또는 하드코딩
                        // 안전하게 하드코딩 된 텍스트로 폴백
                        Text("등록된_카운터가_없습니다".localized == "등록된_카운터가_없습니다" ? "No counters" : "등록된_카운터가_없습니다".localized)
                            .font(.system(size: 14))
                            .foregroundStyle(.gray)
                        
                        Text("watch_add_on_iphone".localized)
                            .font(.system(size: 11))
                            .foregroundStyle(.gray.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    // 카운터 목록 표시
                    ForEach($category.counters) { $counter in
                        NavigationLink(destination: CounterView(counter: $counter, color: category.color)) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(counter.name)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(.white)
                                    Text("tap_to_count".localized)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.gray)
                                }
                                
                                Spacer()
                                
                                // 카운트 값 표시 (정수/소수점 포맷)
                                let displayString = counter.count.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", counter.count) : String(format: "%.1f", counter.count)
                                
                                Text(displayString)
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .foregroundStyle(category.color)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(white: 0.15)) // 카드 배경색
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
