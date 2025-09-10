import SwiftUI

struct TodoView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        NavigationStack {
            List {
                ForEach(app.tasksInActive()) { t in
                    GlassRow {
                        HStack {
                            Button {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                toggle(t)
                            } label: {
                                Image(systemName: t.done ? "checkmark.circle.fill" : "circle")
                            }
                            VStack(alignment: .leading) {
                                Text(t.title).strikethrough(t.done)
                                if let due = t.due {
                                    Text("Due \(due.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.clear)   // ✅ make each row’s background transparent
                }
            }
            .scrollContentBackground(.hidden)        // ✅ removes List’s section bg
            .background(Color.black.ignoresSafeArea()) // ✅ keep whole page black
            .navigationTitle("To-Do")
        }
    }

    func toggle(_ t: TaskItem) {
        if let idx = app.tasks.firstIndex(where: { $0.id == t.id }) {
            app.tasks[idx].done.toggle()
            app.save()
        }
    }
}
