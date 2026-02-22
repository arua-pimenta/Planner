import SwiftData
import Foundation

@Model
final class Anotacao {
    var id: UUID
    var titulo: String
    var conteudo: String
    var dataCriacao: Date
    var dataModificacao: Date
    
    var disciplina: Disciplina?
    
    init(titulo: String, conteudo: String = "", disciplina: Disciplina? = nil) {
        self.id = UUID()
        self.titulo = titulo
        self.conteudo = conteudo
        self.dataCriacao = Date()
        self.dataModificacao = Date()
        self.disciplina = disciplina
    }
}
