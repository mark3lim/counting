
//
//  Models.swift
//  My Counting Watch App
//
//  Created by MARKLIM on 2025-12-07.
//
//  데이터 모델 및 앱 상태(AppState)를 정의하는 파일입니다.
//  iOS 앱과 동일한 구조체를 사용하여 데이터를 동기화합니다.
//

import SwiftUI
import Observation

// MARK: - 공유 모델 (iOS 앱과 동일)

struct TallyCounter: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var count: Double
}

struct TallyCategory: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var colorName: String
    var iconName: String
    var counters: [TallyCounter]
    var allowNegative: Bool = false
    var allowDecimals: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // 테마 색상 반환
    var color: Color {
        return AppTheme.getColor(for: colorName)
    }
    
    // 아이콘 이름 반환
    var icon: String {
        return AppTheme.getIcon(for: iconName)
    }
}

// MARK: - 앱 상태 관리 (AppState)

@Observable
class AppState {
    // 카테고리 목록
    // 변경 시(didSet) iPhone으로 데이터를 전송하여 동기화합니다.
    var categories: [TallyCategory] = [] {
        didSet {
            // 원격 업데이트가 아닌 로컬 변경일 경우에만 전송
            if !isRemoteUpdate {
                ConnectivityProvider.shared.send(categories: categories)
            }
        }
    }
    
    // 원격 업데이트 중 무한 루프 방지를 위한 플래그
    private var isRemoteUpdate = false
    
    init() {
        // 초기화 시 빈 배열로 시작
        categories = []
        
        // ConnectivityProvider로부터 데이터 수신 시 처리
        ConnectivityProvider.shared.onReceiveCategories = { [weak self] newCategories in
            DispatchQueue.main.async {
                self?.isRemoteUpdate = true
                self?.categories = newCategories
                self?.isRemoteUpdate = false
            }
        }
        
        // 초기 데이터 요청 (iPhone에 최신 데이터 요청)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ConnectivityProvider.shared.requestData()
        }
    }
    
    // 특정 카운터 값 업데이트 메서드
    func updateCount(categoryId: UUID, counterId: UUID, delta: Double) {
        if let catIndex = categories.firstIndex(where: { $0.id == categoryId }),
           let ctrIndex = categories[catIndex].counters.firstIndex(where: { $0.id == counterId }) {
            
            var newCount = categories[catIndex].counters[ctrIndex].count + delta
            
            // 음수 허용 여부 체크
            if !categories[catIndex].allowNegative && newCount < 0 { newCount = 0 }
            
            // 소수점 첫째 자리 반올림
            newCount = (newCount * 10).rounded() / 10
            
            categories[catIndex].counters[ctrIndex].count = newCount
        }
    }
    
    // 카테고리 전체 업데이트 메서드
    func updateCategories(_ newCategories: [TallyCategory], isRemote: Bool = false) {
        if isRemote {
            isRemoteUpdate = true
        }
        self.categories = newCategories
        if isRemote {
            isRemoteUpdate = false
        }
    }
}
