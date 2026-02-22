import SwiftUI
import SwiftData

struct NovaAnotacaoSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Disciplina.nome) private var disciplinas: [Disciplina]
    
    @Binding var selectedAnotacao: Anotacao?
    
    @State private var titulo = ""
    @State private var disciplinaSelecionada: Disciplina?
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Título da Anotação", text: $titulo)
                
                Picker("Disciplina (Opcional)", selection: $disciplinaSelecionada) {
                    Text("Nenhuma").tag(Disciplina?.none)
                    ForEach(disciplinas) { disc in
                        Text(disc.nome).tag(Optional(disc))
                    }
                }
            }
            .padding()
            .frame(width: 400, height: 150)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Criar") {
                        let nova = Anotacao(titulo: titulo, conteudo: "", disciplina: disciplinaSelecionada)
                        modelContext.insert(nova)
                        selectedAnotacao = nova
                        dismiss()
                    }
                    .disabled(titulo.isEmpty)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}
