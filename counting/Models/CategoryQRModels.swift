//
//  CategoryQRModels.swift
//  counting
//
//  QR 코드 공유를 위한 데이터 모델
//

import Foundation
import SwiftUI

/// QR 코드 단계 정의
enum QRCodeStep: Int {
    case basicInfo = 0  // 카테고리 기본 정보 (이름, 색상, 아이콘)
    case countingData = 1  // 카운팅 데이터 (카운터들과 값)
}

/// 카테고리 기본 정보 전용 구조체
struct CategoryBasicInfo: Codable {
    let id: UUID
    let name: String
    let icon: String
    let colorName: String  // 색상 이름 문자열 (예: "bg-blue-500")
    
    init(from category: TallyCategory) {
        self.id = category.id
        self.name = category.name
        self.icon = category.iconName
        self.colorName = category.colorName  // 직접 문자열 저장
    }
}

/// 카운팅 데이터 전용 구조체
struct CategoryCountingData: Codable {
    let categoryId: UUID
    let counters: [TallyCounter]
    
    init(from category: TallyCategory) {
        self.categoryId = category.id
        self.counters = category.counters
    }
}
