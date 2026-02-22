import SwiftUI

struct SidebarView: View {
    @Binding var selectedModule: AppModule?
    
    var body: some View {
        List(selection: $selectedModule) {
            Section("Principal") {
                moduleRow(.painel)
                moduleRow(.horario)
                moduleRow(.agenda)
                moduleRow(.tarefas)
            }
            
            Section("Acadêmico") {
                moduleRow(.disciplinas)
                moduleRow(.presenca)
                moduleRow(.caderno)
                moduleRow(.boletim)
            }
            
            Section("Contatos") {
                moduleRow(.professores)
            }
            
            Section("Sistema") {
                moduleRow(.configuracoes)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("MedPlanner")
    }
    
    @ViewBuilder
    private func moduleRow(_ module: AppModule) -> some View {
        NavigationLink(value: module) {
            SidebarRow(
                icon: module.icon,
                title: module.rawValue,
                color: module.color,
                isSelected: selectedModule == module
            )
        }
        .ifLet(module.shortcutKey) { view, key in
            view.keyboardShortcut(key, modifiers: .command)
        }
    }
}

extension View {
    @ViewBuilder func ifLet<T, V: View>(_ value: T?, transform: (Self, T) -> V) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}
