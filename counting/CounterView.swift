import SwiftUI
import AudioToolbox

struct TallyCounterView: View {
    let categoryId: UUID
    let counterId: UUID
    var onDismiss: (() -> Void)? = nil
    @EnvironmentObject var store: TallyStore
    @Environment(\.presentationMode) var presentationMode

    @State private var scale: CGFloat = 1.0
    @State private var ripples: [Ripple] = []

    // Rename Popup States
    @State private var showingRenamePopup = false
    @State private var showingResetAlert = false
    @State private var renameText = ""

    @State private var isScreenAlwaysOn = false
    @State private var showToast = false
    @State private var toastMessage = ""
    
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled = true

    struct Ripple: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat = 0
        var opacity: Double = 0.4
    }

    var category: TallyCategory? {
        store.categories.first(where: { $0.id == categoryId })
    }

    var counter: TallyCounter? {
        category?.counters.first(where: { $0.id == counterId })
    }

    var body: some View {
        if let category = category, let counter = counter {
            ZStack {
                // Background
                category.color
                    .ignoresSafeArea(.all)

                // Main Touch Area (Placed first to be behind controls)
                GeometryReader { geometry in
                    ZStack {
                        // 1. Layout Enforcer & Background for Ripples
                        Color.clear
                            .allowsHitTesting(false) // Ensure this doesn't block or catch touches
                        
                        // 2. Ripples (Visuals)
                        ForEach(ripples) { ripple in
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: 100, height: 100)
                                .scaleEffect(ripple.scale)
                                .opacity(ripple.opacity)
                                .position(x: ripple.x, y: ripple.y)
                        }

                        // 3. Text Info (Visuals)
                        VStack {
                            Text("\(counter.count)")
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
                        .allowsHitTesting(false) // Let touches pass through text to the gesture view

                        // 4. Touch Area (Restricted to center 50%)
                        Color.clear
                            .contentShape(Rectangle())
                            .frame(height: geometry.size.height * 0.5)
                            .gesture(
                                DragGesture(minimumDistance: 0, coordinateSpace: .named("CounterArea"))
                                    .onEnded { value in
                                        triggerIncrement(location: value.location)
                                    }
                            )
                    }
                    .coordinateSpace(name: "CounterArea")
                }
                .ignoresSafeArea()

                // Header (Placed after touch area to be clickable)
                VStack {
                    HStack {
                        Button(action: {
                            if let onDismiss = onDismiss {
                                onDismiss()
                            } else {
                                presentationMode.wrappedValue.dismiss()
                            }
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
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                                .textCase(.uppercase)
                            
                            Text(counter.name)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        
                        Button(action: {
                            renameText = counter.name
                            showingRenamePopup = true
                        }) {
                            Image(systemName: "pencil")
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

                // Bottom Controls
                VStack {
                    Spacer()
                    HStack {
                        Button(action: {
                            isScreenAlwaysOn.toggle()
                            UIApplication.shared.isIdleTimerDisabled = isScreenAlwaysOn
                            
                            toastMessage = isScreenAlwaysOn ? "화면 꺼짐 방지 설정" : "화면 꺼짐 방지 해제"
                            
                            withAnimation {
                                showToast = true
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    showToast = false
                                }
                            }
                        }) {
                            Image(systemName: isScreenAlwaysOn ? "lightbulb.max.fill" : "lightbulb")
                                .font(.system(size: 24))
                                .foregroundColor(isScreenAlwaysOn ? .yellow : .white)
                                .frame(width: 96, height: 64)
                        }

                        Divider()
                            .frame(height: 30)
                            .background(Color.white.opacity(0.3))

                        Button(action: {
                            showingResetAlert = true
                        }) {
                            Image(systemName: "arrow.counterclockwise.circle")
                            .font(.system(size: 30))
                            .foregroundColor(.red.opacity(0.8))
                            .frame(width: 96, height: 64)
                        }
                        
                        Divider()
                            .frame(height: 30)
                            .background(Color.white.opacity(0.3))

                        Button(action: {
                            store.updateCount(categoryId: categoryId, counterId: counterId, delta: -1)
                            if hapticFeedbackEnabled {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                            if soundEffectsEnabled {
                                AudioServicesPlaySystemSound(1103)
                            }
                        }) {
                            Image(systemName: "minus.circle")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .frame(width: 96, height: 64)
                        }
                    }
                    .background(Material.ultraThinMaterial)
                    .cornerRadius(40)
                    .shadow(radius: 10)
                    .padding(.bottom, 40)
                    .alert(isPresented: $showingResetAlert) {
                        Alert(
                            title: Text("카운터 초기화"),
                            message: Text("정말로 이 카운터를 0으로 초기화하시겠습니까?"),
                            primaryButton: .destructive(Text("초기화")) {
                                store.resetCount(categoryId: categoryId, counterId: counterId)
                            },
                            secondaryButton: .cancel(Text("취소"))
                        )
                    }
                }
            }
            .navigationBarHidden(true)
            .blur(radius: showingRenamePopup ? 5 : 0)
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
            }
            
            // Rename Popup Overlay
            if showingRenamePopup {
                ZStack {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            showingRenamePopup = false
                        }
                    
                    VStack(spacing: 20) {
                        Text("이름 수정")
                            .font(.headline)
                            .padding(.top)
                        
                        TextField("카운터 이름", text: $renameText)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        
                        HStack(spacing: 0) {
                            Button(action: {
                                showingRenamePopup = false
                            }) {
                                Text("취소")
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                            
                            Divider()
                                .frame(height: 44)
                            
                            Button(action: {
                                if !renameText.isEmpty {
                                    store.renameCounter(categoryId: categoryId, counterId: counterId, newName: renameText)
                                    showingRenamePopup = false
                                }
                            }) {
                                Text("확인")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .frame(height: 50)
                        .overlay(
                            Rectangle()
                                .frame(height: 0.5)
                                .foregroundColor(Color.gray.opacity(0.3)),
                            alignment: .top
                        )
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .frame(width: 300)
                    .shadow(radius: 10)
                        .shadow(radius: 10)
                }
                .zIndex(2)
            }
            
            // Toast Message Element
            if showToast {
                VStack {
                    Spacer()
                    Text(toastMessage)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(20)
                        .shadow(radius: 5)
                        .padding(.bottom, 120) // Bottom Controlls 위에 표시
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .zIndex(3)
                .allowsHitTesting(false)
            }
        } else {
            // Fallback view if data is missing
            Color.black.ignoresSafeArea()
                .onAppear {
                    presentationMode.wrappedValue.dismiss()
                }
        }
    }

    func triggerIncrement(location: CGPoint) {
        store.updateCount(categoryId: categoryId, counterId: counterId, delta: 1)
        
        if hapticFeedbackEnabled {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        
        if soundEffectsEnabled {
            AudioServicesPlaySystemSound(1104)
        }

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
