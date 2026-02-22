import SwiftUI
import SwiftData

struct NovoFeriadoSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var nome = ""
    @State private var data = Date()
    @State private var tipo: TipoFeriado = .nacional
    @State private var recorrente = false
    @State private var bloqueiaAulas = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Informações do Feriado") {
                    TextField("Nome (Ex: Natal)", text: $nome)
                    
                    DatePicker("Data de Ocorrência", selection: $data, displayedComponents: [.date])
                    
                    Picker("Tipo de Feriado", selection: $tipo) {
                        ForEach(TipoFeriado.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    
                    Toggle("Repete Anualmente?", isOn: $recorrente)
                    Toggle("Aulas Suspensas/Bloqueio?", isOn: $bloqueiaAulas)
                        .tint(.red)
                }
            }
            .padding()
            .frame(width: 400, height: 260)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Registrar") {
                        let novo = Feriado(nome: nome, data: data, tipo: tipo, recorrente: recorrente, bloqueiaAulas: bloqueiaAulas)
                        modelContext.insert(novo)
                        dismiss()
                    }
                    .disabled(nome.isEmpty)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}
