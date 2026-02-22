import Foundation
import SwiftData

@Model
final class Semestre {
    var id: UUID
    var nome: String
    var dataInicio: Date
    var dataFim: Date
    var isAtivo: Bool
    
    @Relationship(deleteRule: .nullify)
    var disciplinas: [Disciplina] = []
    
    init(nome: String, dataInicio: Date, dataFim: Date, isAtivo: Bool = false) {
        self.id = UUID()
        self.nome = nome
        self.dataInicio = dataInicio
        self.dataFim = dataFim
        self.isAtivo = isAtivo
    }
}
