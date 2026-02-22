import SwiftUI
import SwiftData

struct NovaAvaliacaoSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Disciplina.nome) private var disciplinas: [Disciplina]
    
    @State var disciplinaSelecionada: Disciplina
    @State private var titulo = ""
    @State private var notaObtida: Double = 0.0
    @State private var peso: Double = 1.0
    @State private var data = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Detalhes da Avaliação") {
                    Picker("Disciplina", selection: $disciplinaSelecionada) {
                        ForEach(disciplinas) { disc in
                            Text(disc.nome).tag(disc)
                        }
                    }
                    
                    TextField("Nome (ex: P1, Prova Final)", text: $titulo)
                    
                    DatePicker("Data", selection: $data, displayedComponents: [.date])
                }
                
                Section("Notas e Pesos") {
                    VStack(alignment: .leading) {
                        Text("Nota Obtida: \(String(format: "%.1f", notaObtida))")
                        Slider(value: $notaObtida, in: 0...10, step: 0.1)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Peso: \(String(format: "%.1f", peso))")
                        Slider(value: $peso, in: 0.1...5, step: 0.1)
                    }
                }
            }
            .padding()
            .frame(width: 400, height: 350)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        let nova = Avaliacao(titulo: titulo, notaObtida: notaObtida, peso: peso, data: data, disciplina: disciplinaSelecionada)
                        modelContext.insert(nova)
                        dismiss()
                    }
                    .disabled(titulo.isEmpty)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Registrar Nota")
        }
    }
}
