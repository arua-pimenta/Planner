import SwiftUI
import SwiftData

struct AgendaView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tarefa.dataEntrega) private var tarefas: [Tarefa]
    @Query(sort: \Prova.dataProva) private var provas: [Prova]
    
    @State private var date = Date()
    @State private var showingNovaTarefa = false
    @State private var showingNovaProva = false
    @AppStorage("semestreAtivoGlobalId") private var semestreAtivoGlobalId = ""
    
    var eventosDoDia: (tarefas: [Tarefa], provas: [Prova]) {
        let tarefasGlobal = semestreAtivoGlobalId.isEmpty ? tarefas : tarefas.filter { $0.disciplina?.semestre?.id.uuidString == semestreAtivoGlobalId }
        let provasGlobal = semestreAtivoGlobalId.isEmpty ? provas : provas.filter { $0.disciplina?.semestre?.id.uuidString == semestreAtivoGlobalId }
        
        let tarefasDoDia = tarefasGlobal.filter { Calendar.current.isDate($0.dataEntrega, inSameDayAs: date) }
        let provasDoDia = provasGlobal.filter { Calendar.current.isDate($0.dataProva, inSameDayAs: date) }
        return (tarefasDoDia, provasDoDia)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Coluna Esquerda: Calendário Mensal
            VStack {
                DatePicker(
                    "Selecione uma data",
                    selection: $date,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Spacer()
            }
            .frame(width: 320)
            .background(.ultraThinMaterial)
            
            Divider()
            
            // Coluna Direita: Eventos do Dia Selecionado
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(date.formatted(.dateTime.weekday(.wide)))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Text(date.formatted(.dateTime.day().month(.wide).year()))
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    Button("Ir para Hoje") {
                        date = Date()
                    }
                    .keyboardShortcut("t", modifiers: .command)
                    .buttonStyle(.bordered)
                    
                    Menu {
                        Button("Nova Tarefa para este dia") { showingNovaTarefa = true }
                            .keyboardShortcut("n", modifiers: .command)
                        Button("Nova Prova para este dia") { showingNovaProva = true }
                    } label: {
                        Label("Novo", systemImage: "plus")
                    }
                    .menuStyle(.borderlessButton)
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.regularMaterial)
                
                Divider()
                
                let eventos = eventosDoDia
                if eventos.tarefas.isEmpty && eventos.provas.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.minus")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Nenhum evento neste dia")
                            .font(.headline)
                        Text("Aproveite o dia livre ou adicione uma nova tarefa.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        if !eventos.provas.isEmpty {
                            Section("Provas") {
                                ForEach(eventos.provas) { prova in
                                    ProvaRow(prova: prova)
                                }
                            }
                        }
                        
                        if !eventos.tarefas.isEmpty {
                            Section("Tarefas") {
                                ForEach(eventos.tarefas) { tarefa in
                                    TarefaRow(tarefa: tarefa)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showingNovaTarefa) {
            // Em um app real, iniciaríamos a sheet injetando 'date' como selected date
            NovaTarefaSheet()
        }
        .sheet(isPresented: $showingNovaProva) {
            NovaProvaSheet()
        }
    }
}
