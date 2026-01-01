import SwiftUI

struct ToastView: View {
    let message: String
    var bottomPadding: CGFloat = 50
    
    var body: some View {
        Text(message)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.regularMaterial) // Liquid Glass effect
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
            .padding(.bottom, bottomPadding)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
