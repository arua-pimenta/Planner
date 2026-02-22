import Foundation
import SwiftData

enum TipoFeriado: String, Codable, CaseIterable {
    case nacional = "Nacional"
    case municipal = "Municipal"
    case escolar = "Escolar/Institucional"
    case outro = "Outro"
}

@Model
final class Feriado {
    var id: UUID
    var nome: String
    var data: Date
    var tipo: TipoFeriado
    var recorrente: Bool
    var bloqueiaAulas: Bool
    
    init(nome: String, data: Date, tipo: TipoFeriado = .nacional, recorrente: Bool = false, bloqueiaAulas: Bool = true) {
        self.id = UUID()
        self.nome = nome
        self.data = data
        self.tipo = tipo
        self.recorrente = recorrente
        self.bloqueiaAulas = bloqueiaAulas
    }
}
