//
//  ContentView.swift
//  counting
//
//  Created by MARKLIM on 2025-12-05.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = TallyStore()

    var body: some View {
        HomeView()
            .environmentObject(store)
    }
}

#Preview {
    ContentView()
}
