import SwiftUI

struct AddCategoryView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var store: TallyStore
    @State private var name: String = ""

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("카테고리 이름")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)

                TextField("예: 하루 커피 잔 수", text: $name)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                Button(action: {
                    if !name.isEmpty {
                        store.addCategory(name: name)
                        isPresented = false
                    }
                }) {
                    Text("만들기")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                }
                .disabled(name.isEmpty)
                .opacity(name.isEmpty ? 0.5 : 1.0)

                Spacer()
            }
            .padding()
            .navigationTitle("새 카테고리")
            .navigationBarItems(
                trailing: Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                })
        }
    }
}
