import SwiftUI
import SwiftData

struct NovaTarefaSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Disciplina.nome) private var disciplinas: [Disciplina]
    
    @State private var titulo = ""
    @State private var descricao = ""
    @State private var dataEntrega = Date()
    @State private var disciplinaSelecionada: Disciplina? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Nova Tarefa")
                .font(.headline)
                .padding()
            
            Divider()
            
            Form {
                TextField("Título", text: $titulo)
                TextField("Descrição (Opcional)", text: $descricao)
                
                DatePicker("Entrega", selection: $dataEntrega, displayedComponents: [.date, .hourAndMinute])
                
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
                    let nova = Tarefa(titulo: titulo, descricao: descricao, dataEntrega: dataEntrega, disciplina: disciplinaSelecionada)
                    modelContext.insert(nova)
                    NotificationManager.shared.scheduleTaskReminder(for: nova.id, title: nova.titulo, date: nova.dataEntrega)
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
