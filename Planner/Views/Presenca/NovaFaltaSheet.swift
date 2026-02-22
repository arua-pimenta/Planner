import SwiftUI
import SwiftData

struct NovaFaltaSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Disciplina.nome) private var disciplinas: [Disciplina]
    @AppStorage("semestreAtivoGlobalId") private var semestreAtivoGlobalId = ""
    
    var disciplinasFiltradas: [Disciplina] {
        if semestreAtivoGlobalId.isEmpty { return disciplinas }
        return disciplinas.filter { $0.semestre?.id.uuidString == semestreAtivoGlobalId }
    }
    
    @State var disciplinaSelecionada: Disciplina
    @State private var data = Date()
    @State private var quantidadeHoras = 2
    @State private var observacao = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Detalhes da Falta") {
                    Picker("Disciplina", selection: $disciplinaSelecionada) {
                        ForEach(disciplinasFiltradas) { disc in
                            Text(disc.nome).tag(disc)
                        }
                    }
                    
                    DatePicker("Data", selection: $data, displayedComponents: [.date])
                    
                    Stepper("Horas: \(quantidadeHoras)h", value: $quantidadeHoras, in: 1...10)
                }
                
                Section("Observações Opcionais") {
                    TextField("Motivo (Ex: Consulta Médica)", text: $observacao)
                }
            }
            .padding()
            .frame(width: 400, height: 250)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        let nova = Falta(data: data, quantidadeHoras: quantidadeHoras, observacao: observacao, disciplina: disciplinaSelecionada)
                        modelContext.insert(nova)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Registrar Falta")
        }
    }
}
