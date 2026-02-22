import SwiftUI
import SwiftData

struct AnotacoesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.globalSearchText) private var searchText
    @Query(sort: \Anotacao.dataModificacao, order: .reverse) private var anotacoes: [Anotacao]
    
    @State private var selectedAnotacao: Anotacao?
    @State private var showingNovaAnotacao = false
    
    var anotacoesFiltradas: [Anotacao] {
        if searchText.isEmpty { return anotacoes }
        return anotacoes.filter { 
            $0.titulo.localizedCaseInsensitiveContains(searchText) || 
            $0.conteudo.localizedCaseInsensitiveContains(searchText) ||
            ($0.disciplina?.nome.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Coluna Esquerda: Lista de Anotações
            VStack(spacing: 0) {
                HStack {
                    Text("Caderno")
                        .font(.headline)
                    Spacer()
                    Button(action: { showingNovaAnotacao = true }) {
                        Image(systemName: "square.and.pencil")
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(.regularMaterial)
                
                Divider()
                
                if anotacoesFiltradas.isEmpty {
                    Spacer()
                    Text(searchText.isEmpty ? "Nenhuma Anotação" : "Nenhum resultado encontrado")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List(selection: $selectedAnotacao) {
                        ForEach(anotacoesFiltradas) { anotacao in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(anotacao.titulo)
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                if let disc = anotacao.disciplina {
                                    Text(disc.nome)
                                        .font(.caption)
                                        .foregroundColor(Color(hex: disc.corHexCode))
                                }
                                
                                Text(anotacao.dataModificacao, style: .date)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .tag(anotacao)
                            .padding(.vertical, 4)
                            .contextMenu {
                                Button("Apagar", role: .destructive) {
                                    if selectedAnotacao == anotacao { selectedAnotacao = nil }
                                    modelContext.delete(anotacao)
                                }
                            }
                        }
                    }
                    .listStyle(.sidebar)
                }
            }
            .frame(width: 250)
            
            Divider()
            
            // Coluna Direita: Editor / View
            if let anotacao = selectedAnotacao {
                AnotacaoDetailView(anotacao: anotacao)
            } else {
                VStack {
                    Image(systemName: "note.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                    Text("Selecione uma anotação")
                        .font(.headline)
                    Text("Ou crie uma nova para começar a escrever.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
            }
        }
        .sheet(isPresented: $showingNovaAnotacao) {
            NovaAnotacaoSheet(selectedAnotacao: $selectedAnotacao)
        }
    }
}
