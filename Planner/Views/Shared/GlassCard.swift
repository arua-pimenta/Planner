import SwiftUI

enum GlassCardVariant {
    case primary
    case alert
    case selected
    
    var borderColor: Color {
        switch self {
        case .primary: return Color.primary.opacity(0.15)
        case .alert: return Color.red.opacity(0.3)
        case .selected: return Color.blue.opacity(0.3)
        }
    }
}

struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    var variant: GlassCardVariant = .primary
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        content()
            .padding()
            .background(colorScheme == .dark ? .ultraThickMaterial : .ultraThinMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(variant.borderColor, lineWidth: 1)
            )
            .shadow(color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}
