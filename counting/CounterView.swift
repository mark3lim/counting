import SwiftUI

struct TallyCounterView: View {
    let category: TallyCategory
    let counter: TallyCounter
    @EnvironmentObject var store: TallyStore
    @Environment(\.presentationMode) var presentationMode

    @State private var scale: CGFloat = 1.0
    @State private var ripples: [Ripple] = []

    struct Ripple: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat = 0
        var opacity: Double = 0.4
    }

    var liveCounter: TallyCounter {
        store.categories.first(where: { $0.id == category.id })?
            .counters.first(where: { $0.id == counter.id }) ?? counter
    }

    var body: some View {
        ZStack {
            // Background
            category.color
                .ignoresSafeArea(.all)

            // Header
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    Spacer()
                    VStack {
                        Text(category.name)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.7))
                            .textCase(.uppercase)
                        Text(liveCounter.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Button(action: {
                        // More action
                    }) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.black.opacity(0.2), .clear]), startPoint: .top,
                        endPoint: .bottom)
                )
                Spacer()
            }

            // Main Touch Area
            GeometryReader { geometry in
                ZStack {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    triggerIncrement(location: value.location)
                                }
                        )

                    // Ripples
                    ForEach(ripples) { ripple in
                        Circle()
                            .fill(Color.white.opacity(0.4))
                            .frame(width: 100, height: 100)
                            .scaleEffect(ripple.scale)
                            .opacity(ripple.opacity)
                            .position(x: ripple.x, y: ripple.y)
                    }

                    VStack {
                        Text("\(liveCounter.count)")
                            .font(.system(size: 140, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(radius: 10)
                            .scaleEffect(scale)

                        Text("TAP TO COUNT")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.1))
                            .cornerRadius(20)
                    }
                }
            }

            // Bottom Controls
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        store.updateCount(categoryId: category.id, counterId: counter.id, delta: -1)
                    }) {
                        Image(systemName: "minus")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                    }

                    Divider()
                        .frame(height: 30)
                        .background(Color.white.opacity(0.3))

                    Button(action: {
                        store.resetCount(categoryId: category.id, counterId: counter.id)
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                            .foregroundColor(.red.opacity(0.8))
                            .frame(width: 60, height: 60)
                    }
                }
                .background(Material.ultraThinMaterial)
                .cornerRadius(40)
                .shadow(radius: 10)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }

    func triggerIncrement(location: CGPoint) {
        store.updateCount(categoryId: category.id, counterId: counter.id, delta: 1)

        // Bump Animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.3, blendDuration: 0)) {
            scale = 1.15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                scale = 1.0
            }
        }

        // Ripple Effect
        let newRipple = Ripple(x: location.x, y: location.y)
        ripples.append(newRipple)

        // Remove ripple after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if let index = ripples.firstIndex(where: { $0.id == newRipple.id }) {
                ripples.remove(at: index)
            }
        }
    }
}
