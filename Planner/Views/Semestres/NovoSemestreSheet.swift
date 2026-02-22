import SwiftUI
import SwiftData

struct NovoSemestreSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var nome = ""
    @State private var dataInicio = Date()
    @State private var dataFim = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var isAtivo = true
    
    var isValid: Bool {
        !nome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && dataFim > dataInicio
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome (ex: 2024.1, 1º Semestre)", text: $nome)
                    
                    DatePicker("Início", selection: $dataInicio, displayedComponents: .date)
                    DatePicker("Fim", selection: $dataFim, displayedComponents: .date)
                        .onChange(of: dataInicio) { _, num in
                            if dataFim <= dataInicio {
                                dataFim = Calendar.current.date(byAdding: .month, value: 6, to: dataInicio) ?? dataInicio
                            }
                        }
                    
                    Toggle("Definir como semestre ativo", isOn: $isAtivo)
                }
            }
            .padding()
            .navigationTitle("Novo Semestre")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        salvar()
                    }
                    .disabled(!isValid)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .frame(width: 400, height: 300)
        }
    }
    
    private func salvar() {
        if isAtivo {
            // Desativa os outros para manter a semântica "apenas 1 semestre atual"
            let descriptor = FetchDescriptor<Semestre>(predicate: #Predicate { $0.isAtivo == true })
            if let semestresAtivos = try? modelContext.fetch(descriptor) {
                for s in semestresAtivos {
                    s.isAtivo = false
                }
            }
        }
        
        let novoSemestre = Semestre(
            nome: nome.trimmingCharacters(in: .whitespacesAndNewlines),
            dataInicio: dataInicio,
            dataFim: dataFim,
            isAtivo: isAtivo
        )
        
        modelContext.insert(novoSemestre)
        dismiss()
    }
}
