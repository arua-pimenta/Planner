import SwiftUI
import SwiftData

struct SemestresView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.globalSearchText) private var searchText
    @Query(sort: \Semestre.dataInicio, order: .reverse) private var semestres: [Semestre]
    
    @State private var showingNovoSemestre = false
    
    var semestresFiltrados: [Semestre] {
        if searchText.isEmpty { return semestres }
        return semestres.filter { $0.nome.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Semestres e Histórico")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Gerencie seus períodos letivos e histórico.")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { showingNovoSemestre = true }) {
                        Label("Novo Semestre", systemImage: "plus")
                    }
                    .keyboardShortcut("n", modifiers: .command)
                    .buttonStyle(.borderedProminent)
                }
                
                if semestresFiltrados.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "rectangle.stack.badge.play")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text(searchText.isEmpty ? "Nenhum semestre cadastrado" : "Nenhum resultado encontrado")
                            .font(.headline)
                        if searchText.isEmpty {
                            Text("Adicione semestres para organizar suas disciplinas por período.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 20)], spacing: 20) {
                        ForEach(semestresFiltrados) { semestre in
                            SemestreCard(semestre: semestre)
                        }
                    }
                }
            }
            .padding(32)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingNovoSemestre) {
            NovoSemestreSheet()
        }
    }
}

struct SemestreCard: View {
    @Bindable var semestre: Semestre
    @Environment(\.modelContext) private var modelContext
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(semestre.nome)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("\(semestre.dataInicio.formatted(date: .abbreviated, time: .omitted)) - \(semestre.dataFim.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if semestre.isAtivo {
                        StatusBadge(status: .ativo)
                    } else {
                        StatusBadge(status: .concluido)
                    }
                }
                
                Divider()
                
                HStack {
                    Label("\(semestre.disciplinas.count) Disciplinas", systemImage: "books.vertical")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Toggle("Atual", isOn: $semestre.isAtivo)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .onChange(of: semestre.isAtivo) { _, newValue in
                            if newValue {
                                // Se ativou este, garantir que desativa os demais para haver apenas 1 principal (Opcional, mas útil)
                            }
                        }
                }
            }
            .contextMenu {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Excluir Semestre", systemImage: "trash")
                }
            }
            .confirmationDialog("Excluir Semestre?", isPresented: $showingDeleteConfirmation) {
                Button("Excluir", role: .destructive) {
                    modelContext.delete(semestre)
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Isso removerá o semestre e deixará suas disciplinas sem associação. Deseja continuar?")
            }
        }
    }
}
