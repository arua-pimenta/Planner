import SwiftUI
import SwiftData

@Model
final class Disciplina {
    var id: UUID
    var nome: String
    var sigla: String
    var professor: String?
    var corHexCode: String
    
    @Relationship(deleteRule: .cascade)
    var tarefas: [Tarefa] = []
    
    @Relationship(inverse: \Semestre.disciplinas)
    var semestre: Semestre?
    
    @Relationship(deleteRule: .cascade)
    var provas: [Prova] = []
    @Relationship(deleteRule: .cascade)
    var faltas: [Falta] = []
    
    @Relationship(deleteRule: .cascade)
    var anotacoes: [Anotacao] = []
    @Relationship(deleteRule: .cascade)
    var avaliacoes: [Avaliacao] = []
    
    var cargaHorariaTotal: Int?
    var limiteFaltasPercentual: Double?
    
    init(nome: String, sigla: String, professor: String? = nil, corHexCode: String = "#1B3FE8", cargaHorariaTotal: Int? = nil, limiteFaltasPercentual: Double? = 0.25) {
        self.id = UUID()
        self.nome = nome
        self.sigla = sigla
        self.professor = professor
        self.corHexCode = corHexCode
        self.cargaHorariaTotal = cargaHorariaTotal
        self.limiteFaltasPercentual = limiteFaltasPercentual
    }
}
