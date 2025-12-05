//
//  ContentView.swift
//  counting
//
//  Created by MARKLIM on 2025-12-05.
//

import SwiftUI

// 앱의 최상위 컨테이너 뷰
// 데이터 저장소(TallyStore)를 생성하고 하위 뷰에 환경 객체로 전달합니다.
struct ContentView: View {
    // 앱 전체에서 공유될 데이터 저장소를 생성합니다.
    // @StateObject는 뷰의 수명 주기 동안 객체가 한 번만 생성되고 유지되도록 보장합니다.
    @StateObject private var store = TallyStore()

    var body: some View {
        // 메인 홈 화면을 표시하며, store 환경 객체를 주입합니다.
        // 이를 통해 하위 뷰들이 store에 접근할 수 있게 됩니다.
        HomeView()
            .environmentObject(store)
    }
}

// SwiftUI 프리뷰를 위한 코드
#Preview {
    ContentView()
}
