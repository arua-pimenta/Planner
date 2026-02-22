import SwiftData
import Foundation

@Model
final class Falta {
    var id: UUID
    var data: Date
    var quantidadeHoras: Int
    var observacao: String?
    
    var disciplina: Disciplina?
    
    init(data: Date = Date(), quantidadeHoras: Int = 1, observacao: String? = nil, disciplina: Disciplina? = nil) {
        self.id = UUID()
        self.data = data
        self.quantidadeHoras = quantidadeHoras
        self.observacao = observacao
        self.disciplina = disciplina
    }
}
