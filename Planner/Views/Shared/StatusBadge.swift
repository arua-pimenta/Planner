import SwiftUI

enum StatusType {
    case concluido
    case atrasado
    case hoje
    case aprovado
    case emRisco
    case reprovado
    case ativo
    
    var label: String {
        switch self {
        case .concluido: return "Concluído"
        case .atrasado: return "Atrasado"
        case .hoje: return "Hoje"
        case .aprovado: return "Aprovado"
        case .emRisco: return "Em Risco"
        case .reprovado: return "Reprovado"
        case .ativo: return "Ativo"
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .concluido, .aprovado, .ativo: return .green
        case .atrasado, .reprovado: return .red
        case .hoje: return .blue
        case .emRisco: return .orange
        }
    }
}

struct StatusBadge: View {
    let status: StatusType
    
    var body: some View {
        Text(status.label)
            .font(.system(size: 11, weight: .bold))
            .textCase(.uppercase)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .foregroundColor(status.badgeColor)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(status.badgeColor.opacity(0.3), lineWidth: 1)
            )
            .background(status.badgeColor.opacity(0.1))
            .cornerRadius(4)
    }
}
