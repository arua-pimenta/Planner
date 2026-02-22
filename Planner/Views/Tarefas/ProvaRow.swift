import SwiftUI
import SwiftData

struct ProvaRow: View {
    @Bindable var prova: Prova
    
    var isFutura: Bool {
        prova.dataProva >= Date()
    }
    
    var body: some View {
        GlassCard {
            HStack(alignment: .center, spacing: 12) {
                VStack {
                    Text(prova.dataProva.formatted(.dateTime.day()))
                        .font(.title2.bold())
                    Text(prova.dataProva.formatted(.dateTime.month()))
                        .font(.caption.uppercaseSmallCaps())
                        .foregroundColor(.secondary)
                }
                .frame(width: 50, height: 50)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: prova.tipo.icon)
                            .foregroundColor(.blue)
                        
                        Text(prova.titulo)
                            .font(.headline)
                        
                        if let nota = prova.notaAlcancada {
                            StatusBadge(status: nota >= 6.0 ? .aprovado : .reprovado) // Simples assumindo media 6
                        }
                    }
                    
                    if !prova.descricao.isEmpty {
                        Text(prova.descricao)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if let disciplina = prova.disciplina {
                        DisciplinaChip(sigla: disciplina.sigla, corHexCode: disciplina.corHexCode)
                    }
                }
                
                Spacer()
                
                if let nota = prova.notaAlcancada {
                    Text(String(format: "%.1f", nota))
                        .font(.title3.bold())
                        .foregroundColor(nota >= 6.0 ? .green : .red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct NovaProvaSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Disciplina.nome) private var disciplinas: [Disciplina]
    
    @State private var titulo = ""
    @State private var descricao = ""
    @State private var dataProva = Date()
    @State private var tipo: TipoProva = .teorica
    @State private var disciplinaSelecionada: Disciplina? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Nova Prova")
                .font(.headline)
                .padding()
            
            Divider()
            
            Form {
                TextField("Título", text: $titulo)
                TextField("Descrição (Opcional)", text: $descricao)
                
                DatePicker("Data e Hora", selection: $dataProva, displayedComponents: [.date, .hourAndMinute])
                
                Picker("Tipo", selection: $tipo) {
                    ForEach(TipoProva.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                
                Picker("Disciplina", selection: $disciplinaSelecionada) {
                    Text("Nenhuma").tag(Disciplina?.none)
                    ForEach(disciplinas) { disc in
                        Text(disc.nome).tag(Optional(disc))
                    }
                }
            }
            .padding()
            
            Divider()
            
            HStack {
                Button("Cancelar") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                
                Spacer()
                
                Button("Salvar") {
                    let nova = Prova(titulo: titulo, descricao: descricao, dataProva: dataProva, tipo: tipo, disciplina: disciplinaSelecionada)
                    modelContext.insert(nova)
                    NotificationManager.shared.scheduleExamReminder(for: nova.id, title: nova.titulo, date: nova.dataProva)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(titulo.isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 350)
    }
}
