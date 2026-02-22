import SwiftUI
import SwiftData

@Model
final class Tarefa {
    var id: UUID
    var titulo: String
    var descricao: String
    var dataEntrega: Date
    var isConcluida: Bool
    
    @Relationship(inverse: \Disciplina.tarefas)
    var disciplina: Disciplina?
    
    init(titulo: String, descricao: String = "", dataEntrega: Date, isConcluida: Bool = false, disciplina: Disciplina? = nil) {
        self.id = UUID()
        self.titulo = titulo
        self.descricao = descricao
        self.dataEntrega = dataEntrega
        self.isConcluida = isConcluida
        self.disciplina = disciplina
    }
}
