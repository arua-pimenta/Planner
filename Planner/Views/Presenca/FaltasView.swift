import SwiftUI
import SwiftData

struct FaltasView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Disciplina.nome) private var disciplinas: [Disciplina]
    
    @AppStorage("semestreAtivoGlobalId") private var semestreAtivoGlobalId = ""
    
    var disciplinasFiltradas: [Disciplina] {
        if semestreAtivoGlobalId.isEmpty { return disciplinas }
        return disciplinas.filter { $0.semestre?.id.uuidString == semestreAtivoGlobalId }
    }
    
    @State private var selectedDisciplina: Disciplina?
    @State private var showingNovaFalta = false
    
    var body: some View {
        NavigationStack {
            List(disciplinasFiltradas) { disciplina in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        DisciplinaChip(sigla: disciplina.sigla, corHexCode: disciplina.corHexCode)
                        Spacer()
                        percentualAviso(disciplina: disciplina)
                    }
                    
                    let totalFaltas = disciplina.faltas.reduce(0) { $0 + $1.quantidadeHoras }
                    let cargaTotal = disciplina.cargaHorariaTotal ?? 0
                    
                    if cargaTotal > 0 {
                        ProgressView(value: Double(totalFaltas), total: Double(cargaTotal))
                            .tint(corProgress(disciplina: disciplina, total: totalFaltas))
                        Text("\(totalFaltas) de \(cargaTotal) horas faltadas")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(totalFaltas) horas de falta (Carga Horária Indefinida)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !disciplina.faltas.isEmpty {
                        DisclosureGroup("Histórico de Faltas") {
                            ForEach(disciplina.faltas.sorted(by: { $0.data > $1.data })) { falta in
                                HStack {
                                    Text(falta.data.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                    Spacer()
                                    Text("\(falta.quantidadeHoras)h")
                                        .bold()
                                    if let obs = falta.observacao, !obs.isEmpty {
                                        Text("- \(obs)")
                                            .foregroundColor(.secondary)
                                            .font(.caption2)
                                            .lineLimit(1)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .onDelete { indexSet in
                                apagarFalta(disciplina: disciplina, offsets: indexSet)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                .contextMenu {
                    Button("Adicionar Falta") {
                        selectedDisciplina = disciplina
                        showingNovaFalta = true
                    }
                }
            }
            .listStyle(.inset)
            .navigationTitle("Controle de Presença")
            .toolbar {
                ToolbarItem {
                    Menu {
                        ForEach(disciplinasFiltradas) { disc in
                            Button(disc.nome) {
                                selectedDisciplina = disc
                                showingNovaFalta = true
                            }
                        }
                    } label: {
                        Label("Nova Falta", systemImage: "plus")
                    }
                    .disabled(disciplinasFiltradas.isEmpty)
                }
            }
            .sheet(isPresented: $showingNovaFalta) {
                if let disciplina = selectedDisciplina {
                    NovaFaltaSheet(disciplinaSelecionada: disciplina)
                } else if let primeira = disciplinasFiltradas.first {
                    NovaFaltaSheet(disciplinaSelecionada: primeira)
                }
            }
        }
    }
    
    private func apagarFalta(disciplina: Disciplina, offsets: IndexSet) {
        let faltasOrdenadas = disciplina.faltas.sorted(by: { $0.data > $1.data })
        for index in offsets {
            let falta = faltasOrdenadas[index]
            modelContext.delete(falta)
        }
    }
    
    @ViewBuilder
    private func percentualAviso(disciplina: Disciplina) -> some View {
        let totalFaltas = disciplina.faltas.reduce(0) { $0 + $1.quantidadeHoras }
        let cargaTotal = disciplina.cargaHorariaTotal ?? 0
        let limite = disciplina.limiteFaltasPercentual ?? 0.25
        
        if cargaTotal > 0 {
            let limiteHoras = Double(cargaTotal) * limite
            let percentual = Double(totalFaltas) / limiteHoras
            
            if percentual >= 1.0 {
                StatusBadge(status: .reprovado)
            } else if percentual >= 0.8 {
                StatusBadge(status: .emRisco)
            } else if percentual >= 0.5 {
                Text("Atenção")
                    .font(.caption).bold().foregroundColor(.yellow)
            } else {
                StatusBadge(status: .aprovado)
            }
        } else {
            EmptyView()
        }
    }
    
    private func corProgress(disciplina: Disciplina, total: Int) -> Color {
        let cargaTotal = disciplina.cargaHorariaTotal ?? 0
        let limite = disciplina.limiteFaltasPercentual ?? 0.25
        if cargaTotal > 0 {
            let limiteHoras = Double(cargaTotal) * limite
            let percentual = Double(total) / limiteHoras
            if percentual >= 1.0 { return .red }
            if percentual >= 0.8 { return .orange }
            if percentual >= 0.5 { return .yellow }
        }
        return .green
    }
}
