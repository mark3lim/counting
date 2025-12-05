//
//  ContentView.swift
//  counting
//
//  Created by MARKLIM on 2025-12-05.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "message")
                .imageScale(.large)
                .foregroundStyle(.green)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
