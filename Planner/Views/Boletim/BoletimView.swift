import SwiftUI
import SwiftData
import Charts

struct BoletimView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Disciplina.nome) private var disciplinas: [Disciplina]
    
    @State private var showingNovaAvaliacao = false
    @State private var selectedDisciplina: Disciplina?
    
    // Preparação dos dados do gráfico do Boletim
    private var chartData: [(sigla: String, media: Double, cor: Color)] {
        let items = disciplinas.compactMap { d -> (String, Double, Color)? in
            guard let media = calcularMediaPonderada(disciplina: d) else { return nil }
            return (d.sigla, media, corParaNota(media))
        }
        return items
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Gráfico principal de Desempenho
                if !chartData.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading) {
                            Text("Desempenho Geral")
                                .font(.headline)
                                .padding(.bottom, 8)
                            
                            Chart {
                                ForEach(chartData, id: \.sigla) { item in
                                    BarMark(
                                        x: .value("Disciplina", item.sigla),
                                        y: .value("Média", item.media)
                                    )
                                    .foregroundStyle(item.cor.gradient)
                                    .cornerRadius(6)
                                    .annotation(position: .top) {
                                        Text(String(format: "%.1f", item.media))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                RuleMark(y: .value("Média Esperada", 7.0))
                                    .foregroundStyle(.green.opacity(0.5))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                                    .annotation(position: .trailing, alignment: .leading) {
                                        Text("7.0")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    }
                            }
                            .frame(height: 180)
                            .chartYScale(domain: .automatic(includesZero: true))
                        }
                    }
                    .padding()
                }
                
                List(disciplinas) { disciplina in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        DisciplinaChip(sigla: disciplina.sigla, corHexCode: disciplina.corHexCode)
                        Text(disciplina.nome)
                            .font(.headline)
                        Spacer()
                        mediaBadge(disciplina: disciplina)
                    }
                    
                    if !disciplina.avaliacoes.isEmpty {
                        DisclosureGroup("Avaliações Detalhadas") {
                            ForEach(disciplina.avaliacoes.sorted(by: { $0.data > $1.data })) { avaliacao in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(avaliacao.titulo)
                                            .font(.body)
                                            .bold()
                                        Text(avaliacao.data.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text(String(format: "%.1f", avaliacao.notaObtida))
                                            .font(.title3)
                                            .bold()
                                            .foregroundColor(corParaNota(avaliacao.notaObtida))
                                        Text("Peso: \(String(format: "%.1f", avaliacao.peso))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .onDelete { indexSet in
                                apagarAvaliacoes(disciplina: disciplina, offsets: indexSet)
                            }
                        }
                    } else {
                        Text("Nenhuma avaliação registrada.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
                .contextMenu {
                    Button("Adicionar Nota") {
                        selectedDisciplina = disciplina
                        showingNovaAvaliacao = true
                    }
                }
            }
            .listStyle(.inset)
            }
            .navigationTitle("Boletim e Médias")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        PDFExporter.generateAndSaveBoletimPDF(disciplinas: disciplinas)
                    }) {
                        Label("Exportar PDF", systemImage: "square.and.arrow.up")
                    }
                }
                
                ToolbarItem {
                    Menu {
                        ForEach(disciplinas) { disc in
                            Button(disc.nome) {
                                selectedDisciplina = disc
                                showingNovaAvaliacao = true
                            }
                        }
                    } label: {
                        Label("Nova Avaliação", systemImage: "plus")
                    }
                    .disabled(disciplinas.isEmpty)
                }
            }
            .sheet(isPresented: $showingNovaAvaliacao) {
                if let disciplina = selectedDisciplina {
                    NovaAvaliacaoSheet(disciplinaSelecionada: disciplina)
                } else if let primeira = disciplinas.first {
                    NovaAvaliacaoSheet(disciplinaSelecionada: primeira)
                }
            }
        }
    }
    
    private func apagarAvaliacoes(disciplina: Disciplina, offsets: IndexSet) {
        let sorted = disciplina.avaliacoes.sorted(by: { $0.data > $1.data })
        for index in offsets {
            let item = sorted[index]
            modelContext.delete(item)
        }
    }
    
    private func calcularMediaPonderada(disciplina: Disciplina) -> Double? {
        if disciplina.avaliacoes.isEmpty { return nil }
        var somaNotasPesos = 0.0
        var somaPesos = 0.0
        
        for av in disciplina.avaliacoes {
            somaNotasPesos += (av.notaObtida * av.peso)
            somaPesos += av.peso
        }
        
        if somaPesos == 0 { return 0.0 }
        return somaNotasPesos / somaPesos
    }
    
    @ViewBuilder
    private func mediaBadge(disciplina: Disciplina) -> some View {
        if let media = calcularMediaPonderada(disciplina: disciplina) {
            let color = corParaNota(media)
            HStack {
                Text("Média:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f", media))
                    .font(.headline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.15))
                    .foregroundColor(color)
                    .cornerRadius(6)
            }
        } else {
            EmptyView()
        }
    }
    
    private func corParaNota(_ nota: Double) -> Color {
        if nota >= 7.0 {
            return .green
        } else if nota >= 5.0 {
            return .orange
        } else {
            return .red
        }
    }
}
