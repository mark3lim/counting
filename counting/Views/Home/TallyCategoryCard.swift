//
//  TallyCategoryCard.swift
//  counting
//
//  카테고리 카드 뷰
//  개별 카테고리의 정보를 카드 형태로 시각화하여 보여줍니다.
//  Glassmorphism 스타일 적용
//

import SwiftUI

struct TallyCategoryCard: View {
    let category: TallyCategory

    var body: some View {
        VStack(alignment: .leading) {
            iconSection
            Spacer()
            titleSection
            counterCountSection
        }
        .padding(16)
        .frame(height: 150)
        .background(cardBackground)
        .overlay(cardBorder)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - View Components
    
    private var iconSection: some View {
        HStack {
            Spacer()
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.4))
                    .frame(width: 36, height: 36)
                
                Image(systemName: category.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.black.opacity(0.7))
            }
        }
    }
    
    private var titleSection: some View {
        Text(category.name)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(Color.primary.opacity(0.9))
            .lineLimit(1)
    }
    
    private var counterCountSection: some View {
        HStack(spacing: 4) {
            Text("\(category.counters.count)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
            Text("items_count_suffix".localized)
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .foregroundStyle(Color.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: Capsule())
        .padding(.top, 2)
    }
    
    private var cardBackground: some View {
        ZStack {
            category.color.opacity(0.35)
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
        }
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 24)
            .strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(0.5), .white.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
            .blendMode(.overlay)
    }
}

#Preview {
    TallyCategoryCard(category: TallyCategory(
        name: "운동",
        colorName: "bg-blue-500",
        iconName: "figure.run",
        counters: []
    ))
    .padding()
}
