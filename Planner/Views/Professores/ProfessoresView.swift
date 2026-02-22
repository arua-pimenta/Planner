import SwiftUI
import SwiftData

struct ProfessoresView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Professor.nome) private var professores: [Professor]
    
    @State private var showingNovoProfessor = false
    @State private var selectedProfessor: Professor?
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // Master List
                List(selection: $selectedProfessor) {
                    ForEach(professores) { professor in
                        HStack(spacing: 12) {
                            // Avatar
                            if let fotoData = professor.foto, let nsImage = NSImage(data: fotoData) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.1))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Text(professor.nome.prefix(1).uppercased())
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.accentColor)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(professor.nome)
                                    .font(.headline)
                                
                                if professor.titulo != .nenhum || !professor.especialidade.isEmpty {
                                    let comp = [professor.titulo == .nenhum ? "" : professor.titulo.rawValue, professor.especialidade].filter { !$0.isEmpty }.joined(separator: " - ")
                                    Text(comp)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                        .tag(professor)
                        .contextMenu {
                            Button("Editar") {
                                selectedProfessor = professor
                                showingNovoProfessor = true
                            }
                            Button("Apagar", role: .destructive) {
                                apagarProfessor(professor)
                            }
                        }
                    }
                    .onDelete(perform: apagarLista)
                }
                .listStyle(.sidebar) // makes it look like a cohesive sidebar pane
                .frame(width: 320)
                
                Divider()
                
                // Detail Pane
                ZStack {
                    Color(NSColor.windowBackgroundColor).ignoresSafeArea()
                    
                    if let professor = selectedProfessor {
                        ProfessorDetalheView(professor: professor)
                            .id(professor.id)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "person.crop.rectangle.stack")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.5))
                            
                            Text("Selecione um docente")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Docentes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        selectedProfessor = nil
                        showingNovoProfessor = true
                    }) {
                        Label("Novo Professor", systemImage: "plus")
                    }
                }
                
                if selectedProfessor != nil {
                    ToolbarItem(placement: .secondaryAction) {
                        Button("Editar") {
                            showingNovoProfessor = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNovoProfessor) {
                NovoProfessorSheet(professorToEdit: selectedProfessor)
            }
        }
    }
    
    private func apagarLista(offsets: IndexSet) {
        let paraApagar = offsets.map { professores[$0] }
        for professor in paraApagar {
            modelContext.delete(professor)
        }
        if paraApagar.contains(where: { $0.id == selectedProfessor?.id }) {
            selectedProfessor = nil
        }
    }
    
    private func apagarProfessor(_ professor: Professor) {
        modelContext.delete(professor)
        if selectedProfessor?.id == professor.id {
            selectedProfessor = nil
        }
    }
}
