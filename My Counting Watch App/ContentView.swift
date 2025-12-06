
import SwiftUI
import Observation

struct ContentView: View {
    @State private var appState = AppState()
    @State private var showingAddAlert = false
    
    var body: some View {
        @Bindable var bindableAppState = appState
        
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("나의 카운터")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
                
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach($bindableAppState.categories) { $category in
                            NavigationLink(destination: CategoryView(category: $category)) {
                                HStack {
                                    // Icon/Color Dot
                                    Circle()
                                        .fill(category.color)
                                        .frame(width: 10, height: 10)
                                    
                                    Text(category.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    // Total Count
                                    let total = category.counters.reduce(0) { $0 + $1.count }
                                    let displayString = total.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", total) : String(format: "%.1f", total)
                                    
                                    Text(displayString)
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundStyle(.gray)
                                }
                                .padding()
                                .frame(height: 48)
                                .background(Color(white: 0.1)) // gray-900
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Add Button
                        Button(action: {
                            showingAddAlert = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color.gray.opacity(0.2))
                            .foregroundStyle(.gray)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom)
                }
            }
            .background(Color.black)
            .alert("알림", isPresented: $showingAddAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("아이폰 앱에서 추가해주세요.")
            }
        }
    }
}

#Preview {
    ContentView()
}
