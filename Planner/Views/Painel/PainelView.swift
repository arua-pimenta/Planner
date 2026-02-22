import SwiftUI
import SwiftData
import Charts

struct PainelView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("semestreAtivoGlobalId") private var semestreAtivoGlobalId = ""
    
    // Consultas
    @Query private var disciplinas: [Disciplina]
    @Query(sort: \Tarefa.dataEntrega) private var todasTarefas: [Tarefa]
    @Query(sort: \Prova.dataProva) private var proximasProvas: [Prova]
    @Query(sort: \Avaliacao.data) private var avaliacoes: [Avaliacao]
    
    // Filtros Globais de Semestre
    private var disciplinasFiltradas: [Disciplina] {
        if semestreAtivoGlobalId.isEmpty { return disciplinas }
        return disciplinas.filter { $0.semestre?.id.uuidString == semestreAtivoGlobalId }
    }
    
    private var tarefasGlobaisFiltradas: [Tarefa] {
        if semestreAtivoGlobalId.isEmpty { return todasTarefas }
        return todasTarefas.filter { $0.disciplina?.semestre?.id.uuidString == semestreAtivoGlobalId }
    }
    
    private var provasGlobaisFiltradas: [Prova] {
        if semestreAtivoGlobalId.isEmpty { return proximasProvas }
        return proximasProvas.filter { $0.disciplina?.semestre?.id.uuidString == semestreAtivoGlobalId }
    }
    
    private var tarefasPendentes: [Tarefa] {
        tarefasGlobaisFiltradas.filter { !$0.isConcluida }
    }
    
    // Estado local para cálculos
    private var faltasCriticas: [Disciplina] {
        disciplinasFiltradas.filter { d in
            guard let maxP = d.limiteFaltasPercentual, let total = d.cargaHorariaTotal, total > 0 else { return false }
            let faltasCurrent = d.faltas.reduce(into: 0) { total, falta in total += falta.quantidadeHoras }
            let percent = Double(faltasCurrent) / Double(total)
            // Risco se as faltas passarem de 75% do limite (ex: 75% de 25% = 18.75% de falta)
            return percent >= (maxP * 0.75) 
        }
    }
    
    private var mediaGeral: Double {
        let medias = disciplinasFiltradas.compactMap { calcularMedia(da: $0) }
        guard !medias.isEmpty else { return 0.0 }
        return medias.reduce(into: 0.0) { total, m in total += m } / Double(medias.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header / Resumo Rápido
                    HStack(spacing: 20) {
                        ResumoCard(
                            titulo: "Média Global",
                            valor: String(format: "%.1f", mediaGeral),
                            icone: "star.fill",
                            cor: .yellow
                        )
                        
                        ResumoCard(
                            titulo: "Pendentes",
                            valor: "\(tarefasPendentes.count)",
                            icone: "checklist",
                            cor: .red
                        )
                        
                        ResumoCard(
                            titulo: "Disciplinas",
                            valor: "\(disciplinasFiltradas.count)",
                            icone: "books.vertical",
                            cor: .blue
                        )
                    }
                    .padding(.horizontal)
                    
                    // Construtores de Widgets Longos
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible())], spacing: 20) {
                        WidgetGraficoTarefas(todasTarefas: tarefasGlobaisFiltradas)
                        WidgetProximasTarefas(tarefas: Array(tarefasPendentes.prefix(5)))
                        WidgetProximasProvas(proximasProvas: Array(provasGlobaisFiltradas.filter { $0.dataProva >= Date() }.prefix(3)))
                        WidgetAlertasFalta(disciplinasFaltosas: faltasCriticas)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Painel Principal")
        }
    }
    
    private func calcularMedia(da disciplina: Disciplina) -> Double? {
        let evs = disciplina.avaliacoes
        guard !evs.isEmpty else { return nil }
        
        // Forma segura que o compilador SwiftData não surta
        var somaPesos: Double = 0.0
        var somaNotas: Double = 0.0
        
        for ev in evs {
            somaPesos += ev.peso
            somaNotas += (ev.notaObtida * ev.peso)
        }
        
        guard somaPesos > 0 else { return nil }
        return somaNotas / somaPesos
    }
}

// MARK: - Widgets Separados

fileprivate struct ResumoCard: View {
    var titulo: String
    var valor: String
    var icone: String
    var cor: Color
    
    var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                Image(systemName: icone)
                    .font(.system(size: 24))
                    .foregroundColor(cor)
                    .padding(12)
                    .background(cor.opacity(0.2))
                    .clipShape(Circle())
                
                Text(valor)
                    .font(.title)
                    .bold()
                
                Text(titulo)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

fileprivate struct WidgetGraficoTarefas: View {
    var todasTarefas: [Tarefa]
    
    private var data: [(status: String, count: Int, color: Color)] {
        let concluidas = todasTarefas.filter({ $0.isConcluida }).count
        let pendentes = todasTarefas.filter({ !$0.isConcluida }).count
        if concluidas == 0 && pendentes == 0 { return [] }
        return [
            ("Concluídas", concluidas, .green),
            ("Pendentes", pendentes, .orange)
        ]
    }
    
    var body: some View {
        WidgetBase(titulo: "Progresso de Tarefas", icone: "chart.pie.fill", cor: .green) {
            if data.isEmpty {
                Text("Nenhuma tarefa para analisar.")
                    .font(.subheadline).foregroundColor(.secondary)
                    .frame(maxHeight: .infinity)
            } else {
                Chart(data, id: \.status) { item in
                    SectorMark(
                        angle: .value("Quantidade", item.count),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .cornerRadius(4)
                    .foregroundStyle(item.color.gradient)
                    .annotation(position: .overlay) {
                        if item.count > 0 {
                            Text("\(item.count)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        }
                    }
                }
                .chartLegend(position: .bottom, alignment: .center)
                .frame(height: 180)
            }
        }
    }
}

fileprivate struct WidgetProximasTarefas: View {
    var tarefas: [Tarefa]
    
    var body: some View {
        WidgetBase(titulo: "Tarefas Pendentes", icone: "checklist", cor: .orange) {
            if tarefas.isEmpty {
                Text("Tudo em dia! Nenhuma tarefa pendente.")
                    .font(.subheadline).foregroundColor(.secondary)
            } else {
                ForEach(tarefas) { tarefa in
                    HStack {
                        Image(systemName: "circle")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text(tarefa.titulo)
                                .font(.subheadline)
                            Text(tarefa.dataEntrega, style: .date)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

fileprivate struct WidgetAlertasFalta: View {
    var disciplinasFaltosas: [Disciplina]
    
    var body: some View {
        WidgetBase(titulo: "Atenção: Faltas", icone: "exclamationmark.triangle.fill", cor: .red) {
            if disciplinasFaltosas.isEmpty {
                Text("Tranquilo! Nenhuma disciplina em risco.")
                    .font(.subheadline).foregroundColor(.secondary)
            } else {
                ForEach(disciplinasFaltosas) { disc in
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text(disc.sigla)
                            .font(.subheadline)
                        Spacer()
                        Text("Risco")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(4)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

fileprivate struct WidgetProximasProvas: View {
    var proximasProvas: [Prova]
    
    var body: some View {
        WidgetBase(titulo: "Próximas Provas", icone: "doc.text.fill", cor: .purple) {
            if proximasProvas.isEmpty {
                Text("Nenhuma prova agendada para os próximos dias.")
                    .font(.subheadline).foregroundColor(.secondary)
            } else {
                ForEach(proximasProvas) { prova in
                    HStack {
                        Text(prova.dataProva, style: .date)
                            .font(.caption)
                            .foregroundColor(.purple)
                            .frame(width: 50, alignment: .leading)
                        Text(prova.titulo)
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

fileprivate struct WidgetBase<Content: View>: View {
    var titulo: String
    var icone: String
    var cor: Color
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icone)
                        .foregroundColor(cor)
                    Text(titulo)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .padding(.bottom, 4)
                
                content()
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}
