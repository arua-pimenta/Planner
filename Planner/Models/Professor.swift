import Foundation
import SwiftData

enum TituloProfessor: String, Codable, CaseIterable {
    case nenhum = "Nenhum"
    case dr = "Dr."
    case dra = "Dra."
    case prof = "Prof."
    case profa = "Profa."
    case msc = "MSc."
    case esp = "Esp."
}

@Model
final class Professor {
    var id: UUID
    var nome: String
    var titulo: TituloProfessor
    var especialidade: String
    var departamento: String
    var email: String
    var telefone: String
    var whatsapp: String
    var horarioAtendimento: String
    var sala: String
    var anotacoes: String
    
    @Attribute(.externalStorage)
    var foto: Data?
    
    @Relationship(deleteRule: .nullify)
    var disciplinas: [Disciplina] = []
    
    init(nome: String, titulo: TituloProfessor = .nenhum, especialidade: String = "", departamento: String = "", email: String = "", telefone: String = "", whatsapp: String = "", horarioAtendimento: String = "", sala: String = "", anotacoes: String = "", foto: Data? = nil) {
        self.id = UUID()
        self.nome = nome
        self.titulo = titulo
        self.especialidade = especialidade
        self.departamento = departamento
        self.email = email
        self.telefone = telefone
        self.whatsapp = whatsapp
        self.horarioAtendimento = horarioAtendimento
        self.sala = sala
        self.anotacoes = anotacoes
        self.foto = foto
    }
}
