import SwiftUI
import SwiftData

struct TarefaRow: View {
    @Bindable var tarefa: Tarefa
    
    var isAtrasada: Bool {
        !tarefa.isConcluida && tarefa.dataEntrega < Date()
    }
    
    var statusParaBadge: StatusType {
        if tarefa.isConcluida { return .concluido }
        if isAtrasada { return .atrasado }
        
        let isHoje = Calendar.current.isDateInToday(tarefa.dataEntrega)
        if isHoje { return .hoje }
        
        return .aprovado // Fallback
    }
    
    var body: some View {
        GlassCard {
            HStack(alignment: .center, spacing: 12) {
                Button(action: {
                    tarefa.isConcluida.toggle()
                }) {
                    Image(systemName: tarefa.isConcluida ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(tarefa.isConcluida ? .green : .secondary)
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(tarefa.titulo)
                            .font(.headline)
                            .strikethrough(tarefa.isConcluida, color: .secondary)
                            .foregroundColor(tarefa.isConcluida ? .secondary : .primary)
                        
                        if tarefa.isConcluida || isAtrasada || Calendar.current.isDateInToday(tarefa.dataEntrega) {
                            StatusBadge(status: statusParaBadge)
                        }
                    }
                    
                    if !tarefa.descricao.isEmpty {
                        Text(tarefa.descricao)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack(alignment: .center, spacing: 8) {
                        Label(tarefa.dataEntrega.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(isAtrasada ? .red : .secondary)
                        
                        if let disciplina = tarefa.disciplina {
                            DisciplinaChip(sigla: disciplina.sigla, corHexCode: disciplina.corHexCode)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}
