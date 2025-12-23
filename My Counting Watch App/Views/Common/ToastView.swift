
import SwiftUI

struct ToastView: View {
    let message: String
    var bottomPadding: CGFloat = 20
    
    var body: some View {
        VStack {
            Spacer()
            Text(message)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.9))
                .cornerRadius(10)
                .shadow(radius: 3)
                .padding(.bottom, bottomPadding)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .allowsHitTesting(false)
    }
}
