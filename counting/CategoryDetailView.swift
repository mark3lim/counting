import SwiftUI

struct TallyCategoryDetailView: View {
    let categoryId: UUID
    @EnvironmentObject var store: TallyStore
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAddCounter = false

    var liveCategory: TallyCategory? {
        store.categories.first(where: { $0.id == categoryId })
    }

    var body: some View {
        if let category = liveCategory {
            VStack(spacing: 0) {
                // Custom Navigation Bar
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                            .padding()
                    }
                    Text(category.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.top, 10)

                // Counter List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(category.counters, id: \.id) { tallyCounter in
                            NavigationLink(
                                destination: TallyCounterView(
                                    categoryId: category.id, counterId: tallyCounter.id)
                            ) {
                                TallyCounterRow(counter: tallyCounter)
                            }
                        }

                        Button(action: {
                            showingAddCounter = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("새 카운터 추가")
                            }
                            .font(.headline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .foregroundColor(.gray.opacity(0.5))
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddCounter) {
                AddCounterView(isPresented: $showingAddCounter, categoryId: category.id)
            }
        } else {
            // Fallback view when category is not found
            VStack {
                Spacer()
                Text("카테고리를 찾을 수 없습니다.")
                    .font(.headline)
                    .foregroundColor(.gray)
                Button("돌아가기") {
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

struct TallyCounterRow: View {
    let counter: TallyCounter

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(counter.name)
                    .font(.headline)
                    .foregroundColor(.black)
                Text("터치하여 카운팅")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text("\(counter.count)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(24)
    }
}
