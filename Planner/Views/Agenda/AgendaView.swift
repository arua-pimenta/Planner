import SwiftUI
import SwiftData

struct AgendaView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tarefa.dataEntrega) private var tarefas: [Tarefa]
    @Query(sort: \Prova.dataProva) private var provas: [Prova]
    @Query(sort: \Feriado.data) private var feriados: [Feriado]
    
    @State private var date = Date()
    @State private var showingNovaTarefa = false
    @State private var showingNovaProva = false
    @State private var showingNovoFeriado = false
    
    @AppStorage("semestreAtivoGlobalId") private var semestreAtivoGlobalId = ""
    
    // Filtros computados
    var eventosDoDia: (tarefas: [Tarefa], provas: [Prova], feriados: [Feriado]) {
        // Filtragem por Semestre Ativo (Apenas Tarefas e Provas têm semestre, Feriado é global)
        let tarefasGlobal = semestreAtivoGlobalId.isEmpty ? tarefas : tarefas.filter { $0.disciplina?.semestre?.id.uuidString == semestreAtivoGlobalId }
        let provasGlobal = semestreAtivoGlobalId.isEmpty ? provas : provas.filter { $0.disciplina?.semestre?.id.uuidString == semestreAtivoGlobalId }
        
        // Filtragem pelo Dia Selecionado
        let tarefasDoDia = tarefasGlobal.filter { Calendar.current.isDate($0.dataEntrega, inSameDayAs: date) }
        let provasDoDia = provasGlobal.filter { Calendar.current.isDate($0.dataProva, inSameDayAs: date) }
        
        // Feriados recorrentes batem dia e mês, fixos batem dia, mês e ano
        let feriadosDoDia = feriados.filter { feriado in
            let cal = Calendar.current
            if feriado.recorrente {
                let compDate = cal.dateComponents([.month, .day], from: date)
                let compFeriado = cal.dateComponents([.month, .day], from: feriado.data)
                return compDate.month == compFeriado.month && compDate.day == compFeriado.day
            } else {
                return cal.isDate(feriado.data, inSameDayAs: date)
            }
        }
        
        return (tarefasDoDia, provasDoDia, feriadosDoDia)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Coluna Esquerda: Calendário Mensal Estendido
            VStack {
                Text("Calendário")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 24)
                
                CustomCalendarView(selectedDate: $date)
                    .padding()
                    .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                    .cornerRadius(12)
                    .padding(.horizontal)
                
                Spacer()
                
                // Indicação rápida de Feriados no mês selecionado (opcional visual)
                VStack(alignment: .leading, spacing: 8) {
                    Label("Dica", systemImage: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("A visão mensal filtra apenas tarefas do Semestre Selecionado na Toolbar superior. Feriados são globais.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(8)
                .padding()
            }
            .frame(width: 360)
            .background(.ultraThinMaterial)
            
            Divider()
                .overlay(Color(NSColor.separatorColor))
            
            // Coluna Direita: Eventos do Dia Selecionado
            VStack(spacing: 0) {
                // Header customizado "Glass"
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(date.formatted(.dateTime.weekday(.wide)))
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Text(date.formatted(.dateTime.day().month(.wide).year()))
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: { date = Date() }) {
                            Text("Hoje")
                                .fontWeight(.medium)
                        }
                        .keyboardShortcut("t", modifiers: .command)
                        .buttonStyle(.bordered)
                        
                        Menu {
                            Button(action: { showingNovaTarefa = true }) {
                                Label("Nova Tarefa", systemImage: "checklist")
                            }
                            .keyboardShortcut("n", modifiers: .command)
                            
                            Button(action: { showingNovaProva = true }) {
                                Label("Nova Prova", systemImage: "doc.text.fill")
                            }
                            
                            Divider()
                            
                            Button(action: { showingNovoFeriado = true }) {
                                Label("Novo Feriado", systemImage: "calendar.badge.exclamationmark")
                            }
                        } label: {
                            Label("Adicionar", systemImage: "plus.circle.fill")
                                .font(.title3)
                        }
                        .menuStyle(.borderlessButton)
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    }
                }
                .padding(24)
                .background(Color(NSColor.windowBackgroundColor).opacity(0.3))
                
                Divider()
                
                // Lista de Eventos Diários
                let eventos = eventosDoDia
                
                if eventos.tarefas.isEmpty && eventos.provas.isEmpty && eventos.feriados.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.minus")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Sua agenda está livre")
                            .font(.title2)
                            .fontWeight(.medium)
                        Text("Nenhuma tarefa, prova ou feriado marcado para esta data.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(NSColor.textBackgroundColor).opacity(0.3))
                } else {
                    List {
                        // Section: Feriados
                        if !eventos.feriados.isEmpty {
                            Section {
                                ForEach(eventos.feriados) { feriado in
                                    HStack {
                                        Image(systemName: "flag.fill")
                                            .foregroundColor(.red)
                                        VStack(alignment: .leading) {
                                            Text(feriado.nome)
                                                .font(.headline)
                                            Text(feriado.tipo.rawValue)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        if feriado.bloqueiaAulas {
                                            Text("Sem Aulas")
                                                .font(.caption2)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.red.opacity(0.1))
                                                .foregroundColor(.red)
                                                .cornerRadius(8)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            } header: {
                                Text("Feriados Nacionais e Eventos")
                                    .font(.headline)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Section: Provas
                        if !eventos.provas.isEmpty {
                            Section {
                                ForEach(eventos.provas) { prova in
                                    ProvaRow(prova: prova)
                                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                }
                            } header: {
                                Text("Provas")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        // Section: Tarefas Pendentes
                        if !eventos.tarefas.isEmpty {
                            let (pendentes, concluidas) = splitTarefas(eventos.tarefas)
                            
                            if !pendentes.isEmpty {
                                Section {
                                    ForEach(pendentes) { tarefa in
                                        TarefaRow(tarefa: tarefa)
                                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    }
                                } header: {
                                    Text("Pendências de Hoje")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            if !concluidas.isEmpty {
                                Section {
                                    ForEach(concluidas) { tarefa in
                                        TarefaRow(tarefa: tarefa)
                                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    }
                                } header: {
                                    Text("Entregas Concluídas")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color(NSColor.textBackgroundColor).opacity(0.3))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingNovaTarefa) {
            NovaTarefaSheet(initialDate: date)
        }
        .sheet(isPresented: $showingNovaProva) {
            NovaProvaSheet(initialDate: date)
        }
        .sheet(isPresented: $showingNovoFeriado) {
            NovoFeriadoSheet()
        }
    }
    
    private func splitTarefas(_ list: [Tarefa]) -> (pendentes: [Tarefa], concluidas: [Tarefa]) {
        let pendentes = list.filter { !$0.isConcluida }
        let concluidas = list.filter { $0.isConcluida }
        return (pendentes, concluidas)
    }
}

// MARK: - Calendário Customizado
struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentMonth: Date
    
    private let calendar = Calendar.current
    private let daysInWeek = 7
    
    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        self._currentMonth = State(initialValue: selectedDate.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header: Mês e Ano + Botões
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(monthYearString(from: currentMonth))
                    .font(.title3)
                    .fontWeight(.bold)
                    .textCase(.uppercase)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            
            // Dias da Semana
            let firstWeekday = calendar.firstWeekday
            let symbols = calendar.shortWeekdaySymbols
            let shiftedSymbols = Array(symbols[(firstWeekday - 1)...]) + Array(symbols[0..<(firstWeekday - 1)])
            
            HStack {
                ForEach(shiftedSymbols, id: \.self) { symbol in
                    Text(symbol.prefix(3).uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Grid de Dias
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: daysInWeek), spacing: 8) {
                ForEach(0..<days.count, id: \.self) { index in
                    if let date = days[index] {
                        DayCell(date: date, isSelected: calendar.isDate(date, inSameDayAs: selectedDate))
                            .onTapGesture {
                                withAnimation {
                                    selectedDate = date
                                }
                            }
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
    }
    
    private func previousMonth() {
        withAnimation {
            if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
                currentMonth = newDate
            }
        }
    }
    
    private func nextMonth() {
        withAnimation {
            if let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
                currentMonth = newDate
            }
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: date)
    }
    
    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        
        var dates: [Date?] = []
        let firstDayWeekday = calendar.component(.weekday, from: monthInterval.start)
        let firstWeekday = calendar.firstWeekday
        
        var emptyOffsets = firstDayWeekday - firstWeekday
        if emptyOffsets < 0 {
            emptyOffsets += 7
        }
        
        for _ in 0..<emptyOffsets {
            dates.append(nil)
        }
        
        var currentDate = monthInterval.start
        while currentDate < monthInterval.end {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return dates
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        Text(String(Calendar.current.component(.day, from: date)))
            .font(.system(size: 16, weight: isSelected ? .bold : (isToday ? .bold : .regular)))
            .foregroundColor(isSelected ? .white : (isToday ? .accentColor : .primary))
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(isSelected ? Color.accentColor : Color.clear)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(isToday && !isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .contentShape(Rectangle()) // Área de clique realçada
            .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}
