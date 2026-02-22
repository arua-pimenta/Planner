import SwiftUI
import SwiftData

struct TarefasView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.globalSearchText) private var searchText
    @Query(filter: #Predicate<Tarefa> { !$0.isConcluida }, sort: \Tarefa.dataEntrega) private var tarefasPendentes: [Tarefa]
    @Query(filter: #Predicate<Tarefa> { $0.isConcluida }, sort: \Tarefa.dataEntrega, order: .reverse) private var tarefasConcluidas: [Tarefa]
    @Query(sort: \Prova.dataProva) private var provas: [Prova]
    @AppStorage("semestreAtivoGlobalId") private var semestreAtivoGlobalId = ""
    
    @State private var abaSelecionada = 0
    @State private var showingNovaTarefa = false
    @State private var showingNovaProva = false
    
    var tarefasPendentesFiltradas: [Tarefa] {
        let global = semestreAtivoGlobalId.isEmpty ? tarefasPendentes : tarefasPendentes.filter { $0.disciplina?.semestre?.id.uuidString == semestreAtivoGlobalId }
        if searchText.isEmpty { return global }
        return global.filter { $0.titulo.localizedCaseInsensitiveContains(searchText) || ($0.disciplina?.nome.localizedCaseInsensitiveContains(searchText) ?? false) }
    }
    
    var tarefasConcluidasFiltradas: [Tarefa] {
        let global = semestreAtivoGlobalId.isEmpty ? tarefasConcluidas : tarefasConcluidas.filter { $0.disciplina?.semestre?.id.uuidString == semestreAtivoGlobalId }
        if searchText.isEmpty { return global }
        return global.filter { $0.titulo.localizedCaseInsensitiveContains(searchText) || ($0.disciplina?.nome.localizedCaseInsensitiveContains(searchText) ?? false) }
    }
    
    var provasFiltradas: [Prova] {
        let global = semestreAtivoGlobalId.isEmpty ? provas : provas.filter { $0.disciplina?.semestre?.id.uuidString == semestreAtivoGlobalId }
        if searchText.isEmpty { return global }
        return global.filter { $0.titulo.localizedCaseInsensitiveContains(searchText) || ($0.disciplina?.nome.localizedCaseInsensitiveContains(searchText) ?? false) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Tarefas e Provas")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Picker("Visualização", selection: $abaSelecionada) {
                    Text("Pendentes").tag(0)
                    Text("Concluídas").tag(1)
                    Text("Provas").tag(2)
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
                
                Spacer()
                
                Menu {
                    Button("Nova Tarefa") { showingNovaTarefa = true }
                        .keyboardShortcut("n", modifiers: .command)
                    Button("Nova Prova") { showingNovaProva = true }
                } label: {
                    Label("Novo", systemImage: "plus")
                }
                .menuStyle(.borderlessButton)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.regularMaterial)
            
            Divider()
            
            // Content
            Group {
                if abaSelecionada == 0 {
                    ListaTarefas(tarefas: tarefasPendentesFiltradas, mensagemVazia: searchText.isEmpty ? "Nenhuma tarefa pendente!" : "Nenhum resultado encontrado.")
                } else if abaSelecionada == 1 {
                    ListaTarefas(tarefas: tarefasConcluidasFiltradas, mensagemVazia: searchText.isEmpty ? "Nenhuma tarefa concluída." : "Nenhum resultado encontrado.")
                } else {
                    ListaProvas(provas: provasFiltradas, mensagemVazia: searchText.isEmpty ? "Nenhuma prova agendada" : "Nenhum resultado encontrado")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showingNovaTarefa) {
            NovaTarefaSheet()
        }
        .sheet(isPresented: $showingNovaProva) {
            NovaProvaSheet()
        }
    }
}

struct ListaTarefas: View {
    let tarefas: [Tarefa]
    let mensagemVazia: String
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        if tarefas.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "checklist")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text(mensagemVazia)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        } else {
            List {
                ForEach(tarefas) { tarefa in
                    TarefaRow(tarefa: tarefa)
                        .contextMenu {
                            Button(tarefa.isConcluida ? "Marcar como Pendente" : "Marcar como Concluída") {
                                tarefa.isConcluida.toggle()
                            }
                            Button("Excluir", role: .destructive) {
                                modelContext.delete(tarefa)
                            }
                            .keyboardShortcut(.delete, modifiers: .command)
                        }
                }
            }
            .listStyle(.plain)
        }
    }
}

struct ListaProvas: View {
    let provas: [Prova]
    let mensagemVazia: String
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        if provas.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "doc.text")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text(mensagemVazia)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        } else {
            List {
                ForEach(provas) { prova in
                    ProvaRow(prova: prova)
                        .contextMenu {
                            Button("Excluir", role: .destructive) {
                                modelContext.delete(prova)
                            }
                            .keyboardShortcut(.delete, modifiers: .command)
                        }
                }
            }
            .listStyle(.plain)
        }
    }
}
