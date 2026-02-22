import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Query(filter: #Predicate<Tarefa> { !$0.isConcluida }, sort: \Tarefa.dataEntrega)
    var tarefasPendentes: [Tarefa]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Próximas Tarefas")
                .font(.headline)
                .padding(.bottom, 4)
            
            if tarefasPendentes.isEmpty {
                Text("Tudo em dia! Nenhuma tarefa pendente.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(tarefasPendentes.prefix(5)) { tarefa in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle")
                                .foregroundColor(Color(hex: tarefa.disciplina?.corHexCode ?? "#888888"))
                                .font(.system(size: 14))
                                .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tarefa.titulo)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                
                                Text(tarefa.dataEntrega.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // App actions
            VStack(spacing: 8) {
                Button(action: {
                    // Triggers the main app window to come forward
                    if let app = NSApplication.shared.windows.first {
                        app.makeKeyAndOrderFront(nil)
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }) {
                    HStack {
                        Image(systemName: "macwindow")
                        Text("Abrir MedPlanner")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack {
                        Image(systemName: "power")
                        Text("Encerrar")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(width: 280)
    }
}
