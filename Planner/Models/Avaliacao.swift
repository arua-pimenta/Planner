import Foundation
import SwiftData

@Model
final class Avaliacao {
    var id: UUID
    var titulo: String
    var notaObtida: Double
    var peso: Double
    var data: Date
    
    var disciplina: Disciplina?
    
    init(titulo: String, notaObtida: Double, peso: Double = 1.0, data: Date = Date(), disciplina: Disciplina? = nil) {
        self.id = UUID()
        self.titulo = titulo
        self.notaObtida = notaObtida
        self.peso = peso
        self.data = data
        self.disciplina = disciplina
    }
}
