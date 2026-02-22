import Foundation

struct BackupDataDTO: Codable {
    var version: String = "1.3"
    var exportDate: Date = Date()
    
    var semestres: [SemestreDTO] = []
    
    var disciplinas: [DisciplinaDTO]
    var tarefas: [TarefaDTO]
    var provas: [ProvaDTO]
    var faltas: [FaltaDTO]
    var anotacoes: [AnotacaoDTO]
    var avaliacoes: [AvaliacaoDTO]
    var professores: [ProfessorDTO]
    var feriados: [FeriadoDTO]
}

struct DisciplinaDTO: Codable {
    var id: UUID
    var nome: String
    var sigla: String
    var professor: String?
    var corHexCode: String
    var cargaHorariaTotal: Int?
    var limiteFaltasPercentual: Double?
    var semestreId: UUID?
}

struct SemestreDTO: Codable {
    var id: UUID
    var nome: String
    var dataInicio: Date
    var dataFim: Date
    var isAtivo: Bool
}

struct TarefaDTO: Codable {
    var id: UUID
    var titulo: String
    var descricao: String
    var dataEntrega: Date
    var isConcluida: Bool
    var disciplinaId: UUID?
}

struct ProvaDTO: Codable {
    var id: UUID
    var titulo: String
    var descricao: String
    var dataProva: Date
    var notaAlcancada: Double?
    var disciplinaId: UUID?
}

struct FaltaDTO: Codable {
    var id: UUID
    var data: Date
    var quantidadeHoras: Int
    var observacao: String?
    var disciplinaId: UUID?
}

struct AnotacaoDTO: Codable {
    var id: UUID
    var titulo: String
    var conteudo: String
    var dataCriacao: Date
    var dataModificacao: Date
    var disciplinaId: UUID?
}

struct AvaliacaoDTO: Codable {
    var id: UUID
    var titulo: String
    var notaObtida: Double
    var peso: Double
    var data: Date
    var disciplinaId: UUID?
}

struct ProfessorDTO: Codable {
    var id: UUID
    var nome: String
    var email: String
    var departamento: String
    var anotacoes: String
    // Novos campos (opcionais para manter a compatibilidade da importação antiga)
    var titulo: String?
    var especialidade: String?
    var telefone: String?
    var whatsapp: String?
    var horarioAtendimento: String?
    var sala: String?
    var foto: Data?
}

struct FeriadoDTO: Codable {
    var id: UUID
    var nome: String
    var data: Date
    // Novos campos v1.3.6 (Opcionais para compatibilidade traseira)
    var tipo: String?
    var recorrente: Bool?
    var bloqueiaAulas: Bool?
}
