
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
    @EnvironmentObject var appState: AppState
    let categoryId: UUID
    
    // Computed property to get the latest category data safely
    var category: TallyCategory? {
        appState.categories.first { $0.id == categoryId }
    }
    
    var body: some View {
        ScrollView {
            if let category = category {
                VStack(spacing: 8) {
                    if category.counters.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 24))
                                .foregroundStyle(.gray)
                                .padding(.top, 20)
                            
                            Text("no_counters".localized)
                            Text("no_registered_counters".localized)
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
                        // Use indices or just map to pass ID to next view
                        ForEach(category.counters) { counter in
                            NavigationLink(destination: CounterView(categoryId: category.id, counterId: counter.id, color: category.color)) {
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
                                    
                                    let displayString = counter.count.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", counter.count) : String(format: "%.1f", counter.count)
                                    
                                    Text(displayString)
                                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                                        .foregroundStyle(category.color)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(white: 0.15))
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
                .navigationTitle {
                    Label {
                        Text(category.name)
                    } icon: {
                        Image(systemName: category.icon)
                            .scaleEffect(0.75)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("category_not_found".localized)
            }
        }
    }
}
