import SwiftUI
import SwiftData

struct DisciplinasView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.globalSearchText) private var searchText
    @Query(sort: \Disciplina.nome) private var disciplinas: [Disciplina]
    
    @State private var showingNovaDisciplina = false
    
    var disciplinasFiltradas: [Disciplina] {
        if searchText.isEmpty { return disciplinas }
        return disciplinas.filter { 
            $0.nome.localizedCaseInsensitiveContains(searchText) || 
            $0.sigla.localizedCaseInsensitiveContains(searchText) || 
            ($0.professor?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar customizada para o macOS
            HStack {
                Text("Disciplinas")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { showingNovaDisciplina = true }) {
                    Label("Nova", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.regularMaterial)
            
            Divider()
            
            if disciplinasFiltradas.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "Nenhuma disciplina cadastrada" : "Nenhum resultado encontrado")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    if searchText.isEmpty {
                        Button("Adicionar Disciplina") {
                            showingNovaDisciplina = true
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(disciplinasFiltradas) { disciplina in
                        GlassCard {
                            HStack {
                                Circle()
                                    .fill(Color(hex: disciplina.corHexCode))
                                    .frame(width: 12, height: 12)
                                
                                VStack(alignment: .leading) {
                                    Text(disciplina.nome)
                                        .font(.headline)
                                    if let prof = disciplina.professor, !prof.isEmpty {
                                        Text(prof)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                DisciplinaChip(sigla: disciplina.sigla, corHexCode: disciplina.corHexCode)
                            }
                        }
                        .padding(.vertical, 4)
                        .contextMenu {
                            Button("Excluir", role: .destructive) {
                                modelContext.delete(disciplina)
                            }
                            .keyboardShortcut(.delete, modifiers: .command)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .sheet(isPresented: $showingNovaDisciplina) {
            NovaDisciplinaSheet()
        }
    }
}

// Em NovaDisciplinaSheet.swift ou no fim do mesmo arquivo:
struct NovaDisciplinaSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Semestre.dataInicio, order: .reverse) private var semestres: [Semestre]
    
    @State private var nome = ""
    @State private var sigla = ""
    @State private var professor = ""
    @State private var corHex = "#1B3FE8" // Cor padrão
    @State private var semestreSelecionado: Semestre?
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Nova Disciplina")
                .font(.headline)
                .padding()
            
            Divider()
            
            Form {
                TextField("Nome", text: $nome)
                TextField("Sigla", text: $sigla)
                TextField("Professor (Opcional)", text: $professor)
                // Placeholder simples para a cor, ideal seria um ColorPicker customizado que exporta hex
                TextField("Cor HEX", text: $corHex) 
                
                Picker("Semestre", selection: $semestreSelecionado) {
                    Text("Nenhum").tag(Semestre?.none)
                    ForEach(semestres) { semestre in
                        Text(semestre.nome).tag(Semestre?.some(semestre))
                    }
                }
            }
            .padding()
            
            Divider()
            
            HStack {
                Button("Cancelar") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Spacer()
                
                Button("Salvar") {
                    let nova = Disciplina(nome: nome, sigla: sigla, professor: professor.isEmpty ? nil : professor, corHexCode: corHex)
                    nova.semestre = semestreSelecionado
                    modelContext.insert(nova)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(nome.isEmpty || sigla.isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 400)
        .onAppear {
            if let semestreAtivo = semestres.first(where: { $0.isAtivo }) {
                semestreSelecionado = semestreAtivo
            }
        }
    }
}
