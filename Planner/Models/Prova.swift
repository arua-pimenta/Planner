import SwiftUI
import SwiftData

enum TipoProva: String, Codable, CaseIterable, Identifiable {
    case teorica = "Teórica (Múltipla Escolha)"
    case pratica = "Prática (Laboratório/Clínica)"
    case osce = "OSCE"
    case seminario = "Seminário"
    case trabalho = "Trabalho Escrito"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .teorica: return "doc.text.fill"
        case .pratica: return "cross.case.fill"
        case .osce: return "stethoscope"
        case .seminario: return "person.3.sequence.fill"
        case .trabalho: return "doc.append.fill"
        }
    }
}

@Model
final class Prova {
    var id: UUID
    var titulo: String
    var descricao: String
    var dataProva: Date
    var notaAlcancada: Double?
    var tipo: TipoProva

    
    @Relationship(inverse: \Disciplina.provas)
    var disciplina: Disciplina?
    
    init(titulo: String, descricao: String = "", dataProva: Date, notaAlcancada: Double? = nil, tipo: TipoProva = .teorica, disciplina: Disciplina? = nil) {
        self.id = UUID()
        self.titulo = titulo
        self.descricao = descricao
        self.dataProva = dataProva
        self.notaAlcancada = notaAlcancada
        self.tipo = tipo
        self.disciplina = disciplina
    }
}
