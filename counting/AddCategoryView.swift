import SwiftUI

struct AddCategoryView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var store: TallyStore
    @State private var name: String = ""
    @State private var selectedColor: String = AppTheme.allColorNames.first ?? "bg-blue-600"
    @State private var selectedIcon: String = "list"

    let columns = [
        GridItem(.adaptive(minimum: 44))
    ]

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

                Text("색상 선택")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .padding(.top, 10)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(AppTheme.allColorNames, id: \.self) { colorName in
                        ZStack {
                            Circle()
                                .fill(AppTheme.getColor(for: colorName))
                                .frame(width: 44, height: 44)
                                .shadow(color: AppTheme.getColor(for: colorName).opacity(0.5), radius: 3, x: 0, y: 3)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                                .onTapGesture {
                                    selectedColor = colorName
                                }
                            
                            if selectedColor == colorName {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .shadow(radius: 2)
                            }
                        }
                    }
                }
                
                Text("아이콘 선택")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .padding(.top, 10)

                // Icon Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(AppTheme.allIconNames, id: \.self) { iconName in
                            ZStack {
                                Circle()
                                    .fill(selectedIcon == iconName ? Color.black : Color.gray.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: iconName)
                                    .foregroundColor(selectedIcon == iconName ? .white : .gray)
                                    .font(.system(size: 20))
                            }
                            .onTapGesture {
                                selectedIcon = iconName
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
                .frame(maxHeight: 200) // Limit height to avoid taking up too much space

                Button(action: {
                    if !name.isEmpty {
                        store.addCategory(name: name, colorName: selectedColor, iconName: selectedIcon)
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
                        .shadow(radius: 5)
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
