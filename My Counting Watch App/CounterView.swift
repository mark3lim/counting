
import SwiftUI

struct CounterView: View {
    @Binding var counter: CounterItem
    let color: Color
    
    @State private var scale: CGFloat = 1.0
    @State private var showingResetAlert = false
    
    var body: some View {
        ZStack {
            // Background / Main Input
            Color.black.ignoresSafeArea()
            
            VStack {
                // Header (Title)
                Text(counter.name)
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
                    .lineLimit(1)
                    .padding(.top, 2)
                
                Spacer()
                
                // Big Count Display
                Text("\(counter.count)")
                    .font(.system(size: 60, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
                    .scaleEffect(scale)
                    .shadow(radius: 5)
                    .onTapGesture {
                        increment()
                    }
                
                Text("TAP TO COUNT")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Capsule())
                    .padding(.top, 4)
                    .allowsHitTesting(false) // Let taps pass through to the text/background if layout overlaps
                
                Spacer()
                
                // Bottom Controls
                HStack {
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.red)
                            .frame(width: 40, height: 40)
                            .background(Color.red.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button(action: {
                        decrement()
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.gray)
                            .frame(width: 40, height: 40)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
        }
        .contentShape(Rectangle()) // Make entire area tappable for the gesture mainly on the Text, but we can make the background tappable too.
        .onTapGesture {
            increment()
        }
        .alert("카운터 초기화", isPresented: $showingResetAlert) {
            Button("취소", role: .cancel) { }
            Button("초기화", role: .destructive) {
                counter.count = 0
            }
        } message: {
            Text("정말 0으로 초기화하시겠습니까?")
        }
    }
    
    private func increment() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            scale = 1.2
        }
        counter.count += 1
        
        // Reset scale
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                scale = 1.0
            }
        }
    }
    
    private func decrement() {
        if counter.count > 0 {
            counter.count -= 1
        }
    }
    

}

#Preview {
    CounterView(counter: .constant(CounterItem(id: 1, name: "Preview", count: 42)), color: .blue)
}
