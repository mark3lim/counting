//
//  CategoryQRModels.swift
//  counting
//
//  QR 코드 공유를 위한 데이터 모델
//

import Foundation
import SwiftUI

/// 카테고리 전체 데이터 (단일 QR 코드용)
struct CategoryData: Codable, Sendable {
    let id: UUID
    let name: String
    let icon: String
    let colorName: String
    let counters: [TallyCounter]
    
    init(from category: TallyCategory) {
        self.id = category.id
        self.name = category.name
        self.icon = category.iconName
        self.colorName = category.colorName
        self.counters = category.counters
    }
}
