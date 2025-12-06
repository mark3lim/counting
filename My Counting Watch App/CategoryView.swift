
import SwiftUI

struct CategoryView: View {
    @Binding var category: CategoryItem
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach($category.counters) { $counter in
                    NavigationLink(destination: CounterView(counter: $counter, color: category.color)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(counter.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white)
                                Text("탭하여 카운팅")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.gray)
                            }
                            
                            Spacer()
                            
                            Text("\(counter.count)")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundStyle(category.color)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(white: 0.15)) // gray-800 approx
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    CategoryView(category: .constant(CategoryItem(id: 1, name: "Preview", colorName: "blue", iconName: "star", counters: [
        CounterItem(id: 1, name: "Test Counter", count: 10)
    ])))
}
