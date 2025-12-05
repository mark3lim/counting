import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: TallyStore
    @State private var showingAddCategory = false

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color.gray.opacity(0.1).edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    // Header
                    VStack {
                        Text("나의 카운터")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("오늘도 목표를 달성하세요")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                    // TallyCategory Grid
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(store.categories.sorted(by: { $0.updatedAt > $1.updatedAt })) { category in
                                NavigationLink(
                                    destination: TallyCategoryDetailView(categoryId: category.id)
                                ) {
                                    TallyCategoryCard(category: category)
                                }
                            }
                        }
                        .padding()
                    }

                    // Tab Bar (Visual only for now as per prototype)
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: "square.grid.2x2.fill")
                                .font(.system(size: 24))
                            Text("홈")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button(action: {
                            showingAddCategory = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(red: 0.4, green: 0.7, blue: 1.0))
                                .clipShape(Circle())
                                .shadow(radius: 5)
                                .bold()
                        }
                        
                        Spacer()
                        
                        NavigationLink(destination: SettingsView()) {
                            VStack {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 24))
                                Text("설정")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.black)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 10)
                    .background(Color.white)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView(isPresented: $showingAddCategory)
            }
        }
    }
}

struct TallyCategoryCard: View {
    let category: TallyCategory

    var body: some View {
        ZStack(alignment: .topLeading) {
            category.color

            // Glossy Gradient Overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    .white.opacity(0.4),
                    .white.opacity(0.1),
                    .clear,
                    .black.opacity(0.1)
                ]),
                startPoint: .topLeading, endPoint: .bottomTrailing)
            
            // Shine effect
            GeometryReader { geo in
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: geo.size.width, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.white.opacity(0.3), .clear]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }

            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    Image(systemName: category.icon)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(radius: 2)
                }

                Spacer()

                Text(category.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)

                Text("\(category.counters.count)개 항목")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Material.regularMaterial) // 배경 설정을 변경하려면 이 부분을 수정하세요 (예: Color.black.opacity(0.3) 등)
                    .foregroundColor(.black.opacity(0.75))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            }
            .padding()
        }
        .frame(height: 160)
        .cornerRadius(24)
        .shadow(color: category.color.opacity(0.4), radius: 8, x: 0, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView().environmentObject(TallyStore())
    }
}
