import SwiftUI
import SwiftData

struct GlobalSearchTextKey: EnvironmentKey {
    static let defaultValue: String = ""
}

extension EnvironmentValues {
    var globalSearchText: String {
        get { self[GlobalSearchTextKey.self] }
        set { self[GlobalSearchTextKey.self] = newValue }
    }
}


struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Semestre.dataInicio) private var semestres: [Semestre]
    @AppStorage("semestreAtivoGlobalId") private var semestreAtivoGlobalId = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var selectedModule: AppModule? = .painel
    @State private var searchText: String = ""
    @State private var showOnboarding = false
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selectedModule: $selectedModule)
                .navigationSplitViewColumnWidth(min: 220, ideal: 220, max: 280)
        } content: {
            if let selectedModule = selectedModule {
                moduleContent(for: selectedModule)
                    .navigationSplitViewColumnWidth(min: 400, ideal: 600)
            } else {
                Text("Selecione um módulo")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } detail: {
            Text("Detalhes")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: "Busca Global...")
        .environment(\.globalSearchText, searchText)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if !semestres.isEmpty {
                    Picker("Semestre", selection: $semestreAtivoGlobalId) {
                        Text("Geral").tag("") // Opção caso queira ver tudo ou nenhum
                        ForEach(semestres) { semestre in
                            Text(semestre.nome).tag(semestre.id.uuidString)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minWidth: 120)
                }
            }
        }
        .onAppear {
            NotificationManager.shared.requestAuthorization()
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .interactiveDismissDisabled(true)
        }
    }
    
    @ViewBuilder
    private func moduleContent(for module: AppModule) -> some View {
        switch module {
        case .painel:
            PainelView()
        case .horario:
            Text("Horário Semanal")
        case .agenda:
            AgendaView()
        case .tarefas:
            TarefasView()
        case .semestres:
            SemestresView()
        case .disciplinas:
            DisciplinasView()
        case .presenca:
            FaltasView()
        case .caderno:
            AnotacoesView()
        case .boletim:
            BoletimView()
        case .professores:
            ProfessoresView()
        case .feriados:
            FeriadosView()
        case .configuracoes:
            ConfiguracoesView()
        }
    }
}

enum AppModule: String, CaseIterable, Identifiable {
    case painel = "Painel"
    case horario = "Horário"
    case agenda = "Agenda"
    case tarefas = "Tarefas"
    case semestres = "Semestres"
    case disciplinas = "Disciplinas"
    case presenca = "Presença"
    case caderno = "Caderno"
    case boletim = "Boletim"
    case professores = "Professores"
    case feriados = "Feriados"
    case configuracoes = "Configurações"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .painel: return "square.grid.2x2"
        case .horario: return "calendar.day.timeline.left"
        case .agenda: return "calendar"
        case .tarefas: return "checklist"
        case .semestres: return "rectangle.stack.badge.play"
        case .disciplinas: return "books.vertical"
        case .presenca: return "person.crop.circle.badge.checkmark"
        case .caderno: return "book.closed"
        case .boletim: return "graduationcap"
        case .professores: return "person.2"
        case .feriados: return "calendar.badge.clock"
        case .configuracoes: return "gear"
        }
    }
    
    var color: Color {
        switch self {
        case .painel: return .blue
        case .horario: return .orange
        case .agenda: return .red
        case .tarefas: return .green
        case .semestres: return .mint
        case .disciplinas: return .purple
        case .presenca: return .teal
        case .caderno: return .yellow
        case .boletim: return .indigo
        case .professores: return .cyan
        case .feriados: return .pink
        case .configuracoes: return .gray
        }
    }
    
    var shortcutKey: KeyEquivalent? {
        switch self {
        case .painel: return "1"
        case .horario: return "2"
        case .agenda: return "3"
        case .tarefas: return "4"
        case .semestres: return "5"
        case .disciplinas: return "6"
        case .presenca: return "7"
        case .caderno: return "8"
        case .boletim: return "9"
        case .professores: return "0"
        case .feriados: return "-"
        case .configuracoes: return ","
        }
    }
}
