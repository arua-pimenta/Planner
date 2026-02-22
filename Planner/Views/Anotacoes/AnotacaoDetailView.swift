import SwiftUI

struct AnotacaoDetailView: View {
    @Bindable var anotacao: Anotacao
    @State private var isEditing = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                TextField("Título", text: $anotacao.titulo)
                    .font(.title)
                    .textFieldStyle(.plain)
                    .onChange(of: anotacao.titulo) { _, _ in
                        anotacao.dataModificacao = Date()
                    }
                
                Spacer()
                
                Picker("Modo", selection: $isEditing) {
                    Text("Editar").tag(true)
                    Text("Visualizar").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
            .padding()
            .background(.regularMaterial)
            
            Divider()
            
            // Content
            if isEditing {
                TextEditor(text: $anotacao.conteudo)
                    .font(.body)
                    .padding()
                    .onChange(of: anotacao.conteudo) { _, _ in
                        anotacao.dataModificacao = Date()
                    }
            } else {
                ScrollView {
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey(anotacao.conteudo))
                            .textSelection(.enabled)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(.ultraThinMaterial)
            }
        }
    }
}
