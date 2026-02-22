import SwiftUI

struct SidebarRow: View {
    let icon: String
    let title: String
    let color: Color
    var badgeCount: Int? = nil
    var isSelected: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .medium : .regular))
                .foregroundColor(isSelected ? .primary : .secondary)
            
            Spacer()
            
            if let count = badgeCount, count > 0 {
                Text("\(count)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .foregroundColor(color)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.primary.opacity(0.08) : Color.clear)
        .cornerRadius(10)
    }
}
