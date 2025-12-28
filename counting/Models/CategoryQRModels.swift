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
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon, colorName, counters
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.icon = try container.decode(String.self, forKey: .icon)
        self.colorName = try container.decode(String.self, forKey: .colorName)
        self.counters = try container.decode([TallyCounter].self, forKey: .counters)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        try container.encode(colorName, forKey: .colorName)
        try container.encode(counters, forKey: .counters)
    }
}
