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
                    HStack {
                        VStack(alignment: .leading) {
                            Text("나의 카운터")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("오늘도 목표를 달성하세요")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button(action: {
                            showingAddCategory = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                    // TallyCategory Grid
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(store.categories, id: \.id) { category in
                                NavigationLink(
                                    destination: TallyCategoryDetailView(category: category)
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
                        VStack {
                            Image(systemName: "gearshape")
                                .font(.system(size: 24))
                            Text("설정")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.gray)
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

            // Gradient Overlay
            LinearGradient(
                gradient: Gradient(colors: [.white.opacity(0.1), .black.opacity(0.1)]),
                startPoint: .topLeading, endPoint: .bottomTrailing)

            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    Image(systemName: "list.bullet")
                        .foregroundColor(.white.opacity(0.5))
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }

                Spacer()

                Text(category.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("\(category.counters.count)개 항목")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .frame(height: 160)
        .cornerRadius(24)
        .shadow(color: category.color.opacity(0.3), radius: 5, x: 0, y: 5)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView().environmentObject(TallyStore())
    }
}
