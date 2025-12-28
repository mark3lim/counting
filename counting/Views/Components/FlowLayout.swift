
import SwiftUI

// Simple FlowLayout Helper
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        return rows.last?.maxY ?? .zero
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        for row in rows {
            for element in row.elements {
                element.subview.place(at: CGPoint(x: bounds.minX + element.frame.minX, y: bounds.minY + element.frame.minY), proposal: .unspecified)
            }
        }
    }
    
    struct Row {
        var elements: [Element]
        var maxY: CGSize
        
        var height: CGFloat {
            elements.map(\.frame.height).max() ?? 0
        }
    }
    
    struct Element {
        var subview: LayoutSubview
        var frame: CGRect
    }
    
    func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var currentRowElements: [Element] = []
        
        // Handle infinity width case (e.g. inside ScrollView with horizontal scrolling, though usually FlowLayout is vertical)
        let maxWidth = proposal.width ?? .infinity
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            // Check if it fits in current row
            if currentX + size.width > maxWidth, !currentRowElements.isEmpty {
                // New row
                let maxHeight = currentRowElements.map(\.frame.height).max() ?? 0
                rows.append(Row(elements: currentRowElements, maxY: CGSize(width: maxWidth, height: currentY + maxHeight)))
                currentY += maxHeight + spacing
                currentX = 0
                currentRowElements = []
            }
            
            currentRowElements.append(Element(subview: subview, frame: CGRect(x: currentX, y: currentY, width: size.width, height: size.height)))
            currentX += size.width + spacing
        }
        
        if !currentRowElements.isEmpty {
            let maxHeight = currentRowElements.map(\.frame.height).max() ?? 0
            rows.append(Row(elements: currentRowElements, maxY: CGSize(width: maxWidth, height: currentY + maxHeight)))
        }
        
        return rows
    }
}

// Wrapper for ease of use
struct FlowLayoutWrapper: View {
    let items: [String]
    
    var body: some View {
        FlowLayout {
            // 중복된 문자열이 있어도 식별 가능하도록 index(offset)를 id로 사용
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Text(item)
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundStyle(Color.primary)
                    .clipShape(Capsule())
            }
        }
    }
}
