import SwiftUI
import SwiftData

@main
struct MedPlannerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Semestre.self, Disciplina.self, Tarefa.self, Prova.self, Falta.self, Anotacao.self, Avaliacao.self, Professor.self, Feriado.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .frame(minWidth: 900, minHeight: 600)
        }
        .modelContainer(sharedModelContainer)
        
        MenuBarExtra("MedPlanner", systemImage: "graduationcap.fill") {
            MenuBarView()
                .modelContainer(sharedModelContainer)
        }
        .menuBarExtraStyle(.window)
    }
}
