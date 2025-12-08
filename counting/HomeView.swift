import SwiftUI
import UIKit

// 메인 홈 화면 뷰
// 사용자가 등록한 카테고리 목록을 보여주고, 설정 화면이나 카테고리 추가 화면으로 이동할 수 있습니다.
struct HomeView: View {
    // 앱의 데이터 저장소를 환경 객체로 가져옵니다.
    @EnvironmentObject var store: TallyStore
    @ObservedObject var l10n = LocalizationManager.shared
    
    // 카테고리 추가 시트 표시 여부를 제어하는 상태 변수
    @State private var showingAddCategory = false
    
    // 삭제 관련 상태 변수
    @State private var categoryToDelete: TallyCategory?
    @State private var showingDeleteOption = false
    @State private var showingDeleteConfirmation = false
    @State private var deletingCategoryId: UUID? // 삭제 애니메이션 중인 카테고리 ID 추적

    // 그리드 레이아웃 설정 (2열 그리드)
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "f5f7fa"), Color(hex: "c3cfe2")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                // Ambient Orbs (for Glassmorphism depth)
                GeometryReader { geometry in
                    ZStack {
                        Circle()
                            .fill(Color(hex: "a18cd1").opacity(0.4))
                            .frame(width: 300, height: 300)
                            .blur(radius: 60)
                            .offset(x: -100, y: -150)
                        
                        Circle()
                            .fill(Color(hex: "fbc2eb").opacity(0.4))
                            .frame(width: 250, height: 250)
                            .blur(radius: 60)
                            .offset(x: geometry.size.width - 100, y: geometry.size.height / 3)
                        
                         Circle()
                            .fill(Color(hex: "8fd3f4").opacity(0.4))
                            .frame(width: 280, height: 280)
                            .blur(radius: 60)
                            .offset(x: 50, y: geometry.size.height - 200)
                    }
                }
                .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    // 카테고리 목록 그리드 (스크롤 가능)
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 4) {
                            // Title
                            Text("my_counters".localized)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(.primary.opacity(0.8))
                                .padding(.horizontal)
                                .padding(.top, 8)
                            
                            // Subtitle
                            Text("home_greeting_subtitle".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.top, 8)
                            
                            LazyVGrid(columns: columns, spacing: 20) {
                                // 생성일 순으로 정렬하여 표시 (최신순)
                                ForEach(store.categories.sorted(by: { $0.createdAt > $1.createdAt })) { category in
                                    NavigationLink(
                                        destination: TallyCategoryDetailView(categoryId: category.id)
                                    ) {
                                        // 각 카테고리를 카드 형태로 표시하는 뷰
                                        TallyCategoryCard(category: category)
                                            // 수동 애니메이션 적용: 삭제 중이면 축소 및 투명화
                                            .scaleEffect(deletingCategoryId == category.id ? 0.01 : 1.0)
                                            .opacity(deletingCategoryId == category.id ? 0.0 : 1.0)
                                            .animation(.spring(response: 0.33, dampingFraction: 0.6), value: deletingCategoryId)
                                            .allowsHitTesting(deletingCategoryId != category.id)
                                            .onLongPressGesture(minimumDuration: 1.0) {
                                                self.categoryToDelete = category
                                                // 햅틱 피드백 발생
                                                let generator = UIImpactFeedbackGenerator(style: .heavy)
                                                generator.impactOccurred()
                                                self.showingDeleteOption = true
                                            }
                                    }
                                }
                            }
                            .padding()
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .overlay(
                HStack(spacing: 40) {
                    // Settings Button
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.primary.opacity(0.8))
                    }

                    // Add Button
                    Button(action: {
                        showingAddCategory = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary.opacity(0.8))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.bottom, 0)
            , alignment: .bottom)
            .navigationBarHidden(true)
            // 카테고리 추가 모달 시트
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView(isPresented: $showingAddCategory)
            }
            // 1단계: 삭제 옵션 표시 (삭제 버튼)
            .confirmationDialog("category_options".localized, isPresented: $showingDeleteOption, titleVisibility: .visible) {
                Button("delete_category".localized, role: .destructive) {
                    self.showingDeleteConfirmation = true
                }
                Button("cancel".localized, role: .cancel) {}
            } message: {
                Text(categoryToDelete?.name ?? "selected_category".localized)
            }
            // 2단계: 최종 삭제 확인 경고창
            .alert("delete_category_confirmation".localized, isPresented: $showingDeleteConfirmation) {
                Button("delete".localized, role: .destructive) {
                    if let category = categoryToDelete {
                        // 1. 먼저 시각적 축소 애니메이션 실행
                        deletingCategoryId = category.id
                        
                        // 2. 애니메이션이 끝날 때쯤 실제 데이터 삭제
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                store.deleteCategory(categoryId: category.id)
                            }
                            deletingCategoryId = nil
                            categoryToDelete = nil
                        }
                    }
                }
                Button("cancel".localized, role: .cancel) {}
            } message: {
                Text("irreversible_action".localized)
            }
        }
    }
}

// 카테고리 카드 뷰
// 개별 카테고리의 정보를 카드 형태로 시각화하여 보여줍니다.
// Glassmorphism 스타일 적용
struct TallyCategoryCard: View {
    let category: TallyCategory

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 1. Base Glass Material
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
            
            // 2. Subtle Color Tint
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            category.color.opacity(0.15),
                            category.color.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // 3. Glass Border (Reflection)
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .white.opacity(0.6),
                            .white.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            
            // 4. Content
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    // 카테고리 아이콘 표시
                    ZStack {
                        Circle()
                            .fill(category.color.opacity(0.2))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: category.icon)
                            .font(.system(size: 16))
                            .foregroundColor(category.color)
                    }
                }
                
                Spacer()
                
                // 카테고리 이름
                Text(category.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary.opacity(0.9))
                    .lineLimit(1)
                
                // 포함된 카운터 개수 표시
                HStack(spacing: 4) {
                    Text("\(category.counters.count)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                    Text("items_count_suffix".localized)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                }
                .foregroundColor(.secondary)
                .padding(.top, 2)
            }
            .padding(16)
        }
        .frame(height: 150)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView().environmentObject(TallyStore())
    }
}

// MARK: - Helper Structs

// SwiftUI에서 사용할 수 있는 간단한 Blur View (Material 호환성)
struct MaterialEffect: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// 특정 모서리만 둥글게 만들기 위한 Shape
struct CustomCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
