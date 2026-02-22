import Foundation
import SwiftData
import AppKit
import UniformTypeIdentifiers

@MainActor
class BackupManager {
    static let shared = BackupManager()
    
    private init() {}
    
    // MARK: - Export
    func exportData(context: ModelContext) {
        do {
            let backup = try createBackupDTO(context: context)
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            
            let data = try encoder.encode(backup)
            
            let panel = NSSavePanel()
            if let type = UTType("public.json") {
                panel.allowedContentTypes = [type]
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            panel.nameFieldStringValue = "MedPlanner_Backup_\(formatter.string(from: Date())).json"
            
            if panel.runModal() == .OK, let url = panel.url {
                try data.write(to: url)
                print("Backup concluído com sucesso em \(url.path)")
            }
        } catch {
            print("Erro ao exportar dados: \(error)")
        }
    }
    
    private func createBackupDTO(context: ModelContext) throws -> BackupDataDTO {
        let semestres = try context.fetch(FetchDescriptor<Semestre>())
        let disciplinas = try context.fetch(FetchDescriptor<Disciplina>())
        let tarefas = try context.fetch(FetchDescriptor<Tarefa>())
        let provas = try context.fetch(FetchDescriptor<Prova>())
        let faltas = try context.fetch(FetchDescriptor<Falta>())
        let anotacoes = try context.fetch(FetchDescriptor<Anotacao>())
        let avaliacoes = try context.fetch(FetchDescriptor<Avaliacao>())
        let professores = try context.fetch(FetchDescriptor<Professor>())
        let feriados = try context.fetch(FetchDescriptor<Feriado>())
        
        let semestresDTO = semestres.map { s in
            SemestreDTO(id: s.id, nome: s.nome, dataInicio: s.dataInicio, dataFim: s.dataFim, isAtivo: s.isAtivo)
        }
        
        let disciplinasDTO = disciplinas.map { d in
            DisciplinaDTO(id: d.id, nome: d.nome, sigla: d.sigla, professor: d.professor, corHexCode: d.corHexCode, cargaHorariaTotal: d.cargaHorariaTotal, limiteFaltasPercentual: d.limiteFaltasPercentual, semestreId: d.semestre?.id)
        }
        
        let tarefasDTO = tarefas.map { t in TarefaDTO(id: t.id, titulo: t.titulo, descricao: t.descricao, dataEntrega: t.dataEntrega, isConcluida: t.isConcluida, disciplinaId: t.disciplina?.id) }
        let provasDTO = provas.map { p in ProvaDTO(id: p.id, titulo: p.titulo, descricao: p.descricao, dataProva: p.dataProva, notaAlcancada: p.notaAlcancada, disciplinaId: p.disciplina?.id) }
        let faltasDTO = faltas.map { f in FaltaDTO(id: f.id, data: f.data, quantidadeHoras: f.quantidadeHoras, observacao: f.observacao, disciplinaId: f.disciplina?.id) }
        let anotacoesDTO = anotacoes.map { a in AnotacaoDTO(id: a.id, titulo: a.titulo, conteudo: a.conteudo, dataCriacao: a.dataCriacao, dataModificacao: a.dataModificacao, disciplinaId: a.disciplina?.id) }
        let avaliacoesDTO = avaliacoes.map { a in AvaliacaoDTO(id: a.id, titulo: a.titulo, notaObtida: a.notaObtida, peso: a.peso, data: a.data, disciplinaId: a.disciplina?.id) }
        let professoresDTO = professores.map { p in ProfessorDTO(id: p.id, nome: p.nome, email: p.email, departamento: p.departamento, anotacoes: p.anotacoes, titulo: p.titulo.rawValue, especialidade: p.especialidade, telefone: p.telefone, whatsapp: p.whatsapp, horarioAtendimento: p.horarioAtendimento, sala: p.sala, foto: p.foto) }
        let feriadosDTO = feriados.map { f in FeriadoDTO(id: f.id, nome: f.nome, data: f.data, tipo: f.tipo.rawValue, recorrente: f.recorrente, bloqueiaAulas: f.bloqueiaAulas) }
        
        return BackupDataDTO(
            version: "1.3",
            exportDate: Date(),
            semestres: semestresDTO,
            disciplinas: disciplinasDTO,
            tarefas: tarefasDTO,
            provas: provasDTO,
            faltas: faltasDTO,
            anotacoes: anotacoesDTO,
            avaliacoes: avaliacoesDTO,
            professores: professoresDTO,
            feriados: feriadosDTO
        )
    }
    
    // MARK: - Import
    func importData(context: ModelContext) {
        let panel = NSOpenPanel()
        if let type = UTType("public.json") {
            panel.allowedContentTypes = [type]
        }
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let backup = try decoder.decode(BackupDataDTO.self, from: data)
                
                try restoreBackup(backup, context: context)
                print("Backup importado com sucesso!")
            } catch {
                print("Erro ao importar dados. Arquivo malformado ou incompatível.\nDetalhamento: \(error)")
                let alert = NSAlert()
                alert.messageText = "Falha ao Importar"
                alert.informativeText = "O arquivo selecionado não é um backup válido do MedPlanner ou está corrompido."
                alert.alertStyle = .critical
                alert.runModal()
            }
        }
    }
    
    private func restoreBackup(_ backup: BackupDataDTO, context: ModelContext) throws {
        // 1. Limpar banco atual
        try context.delete(model: Feriado.self)
        try context.delete(model: Professor.self)
        try context.delete(model: Avaliacao.self)
        try context.delete(model: Anotacao.self)
        try context.delete(model: Falta.self)
        try context.delete(model: Prova.self)
        try context.delete(model: Tarefa.self)
        try context.delete(model: Disciplina.self)
        try context.delete(model: Semestre.self)
        
        // 1.5 Recriar Semestres e armazenar mapeamento
        var dictSemestres: [UUID: Semestre] = [:]
        for sDTO in backup.semestres {
            let s = Semestre(nome: sDTO.nome, dataInicio: sDTO.dataInicio, dataFim: sDTO.dataFim, isAtivo: sDTO.isAtivo)
            s.id = sDTO.id
            context.insert(s)
            dictSemestres[s.id] = s
        }
        
        // 2. Recriar Disciplinas e armazenar mapeamento
        var dictDisciplinas: [UUID: Disciplina] = [:]
        
        for dDTO in backup.disciplinas {
            let semestre = dDTO.semestreId.flatMap { dictSemestres[$0] }
            let d = Disciplina(nome: dDTO.nome, sigla: dDTO.sigla, professor: dDTO.professor, corHexCode: dDTO.corHexCode, cargaHorariaTotal: dDTO.cargaHorariaTotal, limiteFaltasPercentual: dDTO.limiteFaltasPercentual)
            d.id = dDTO.id // Mantém o ID original
            d.semestre = semestre
            context.insert(d)
            dictDisciplinas[d.id] = d
        }
        
        // 3. Recriar outras entidades e associar à Disciplina
        for tDTO in backup.tarefas {
            let disciplina = tDTO.disciplinaId.flatMap { dictDisciplinas[$0] }
            let t = Tarefa(titulo: tDTO.titulo, descricao: tDTO.descricao, dataEntrega: tDTO.dataEntrega, isConcluida: tDTO.isConcluida, disciplina: disciplina)
            t.id = tDTO.id
            context.insert(t)
        }
        
        for pDTO in backup.provas {
            let disciplina = pDTO.disciplinaId.flatMap { dictDisciplinas[$0] }
            let p = Prova(titulo: pDTO.titulo, descricao: pDTO.descricao, dataProva: pDTO.dataProva, notaAlcancada: pDTO.notaAlcancada, disciplina: disciplina)
            p.id = pDTO.id
            context.insert(p)
        }
        
        for fDTO in backup.faltas {
            let disciplina = fDTO.disciplinaId.flatMap { dictDisciplinas[$0] }
            let f = Falta(data: fDTO.data, quantidadeHoras: fDTO.quantidadeHoras, observacao: fDTO.observacao, disciplina: disciplina)
            f.id = fDTO.id
            context.insert(f)
        }
        
        for aDTO in backup.anotacoes {
            let disciplina = aDTO.disciplinaId.flatMap { dictDisciplinas[$0] }
            let a = Anotacao(titulo: aDTO.titulo, conteudo: aDTO.conteudo, disciplina: disciplina)
            a.id = aDTO.id
            a.dataCriacao = aDTO.dataCriacao
            a.dataModificacao = aDTO.dataModificacao
            context.insert(a)
        }
        
        for aDTO in backup.avaliacoes {
            let disciplina = aDTO.disciplinaId.flatMap { dictDisciplinas[$0] }
            let a = Avaliacao(titulo: aDTO.titulo, notaObtida: aDTO.notaObtida, peso: aDTO.peso, data: aDTO.data, disciplina: disciplina)
            a.id = aDTO.id
            context.insert(a)
        }
        
        // 4. Recriar entidades independentes
        for pDTO in backup.professores {
            let tituloStr = pDTO.titulo ?? ""
            let tituloEnum = TituloProfessor(rawValue: tituloStr) ?? .nenhum
            let p = Professor(
                nome: pDTO.nome,
                titulo: tituloEnum,
                especialidade: pDTO.especialidade ?? "",
                departamento: pDTO.departamento,
                email: pDTO.email,
                telefone: pDTO.telefone ?? "",
                whatsapp: pDTO.whatsapp ?? "",
                horarioAtendimento: pDTO.horarioAtendimento ?? "",
                sala: pDTO.sala ?? "",
                anotacoes: pDTO.anotacoes,
                foto: pDTO.foto
            )
            p.id = pDTO.id
            context.insert(p)
        }
        
        for fDTO in backup.feriados {
            let tipoEnum = TipoFeriado(rawValue: fDTO.tipo ?? "") ?? .nacional
            let f = Feriado(nome: fDTO.nome, data: fDTO.data, tipo: tipoEnum, recorrente: fDTO.recorrente ?? false, bloqueiaAulas: fDTO.bloqueiaAulas ?? true)
            f.id = fDTO.id
            context.insert(f)
        }
        
        try context.save()
    }
}
