import SwiftUI

struct BoletimPDFView: View {
    var disciplinas: [Disciplina]
    
    // Dimensões A4 em pontos: 595 x 842
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header do Relatório
            HStack {
                VStack(alignment: .leading) {
                    Text("MedPlanner")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.blue)
                    Text("Relatório Semestral - Boletim")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(Date().formatted(date: .long, time: .omitted))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 20)
            
            Divider()
            
            // Corpo - Tabela de Disciplinas
            if disciplinas.isEmpty {
                Text("Nenhuma disciplina cadastrada neste semestre.")
                    .font(.headline)
                    .padding(.top, 40)
            } else {
                ForEach(disciplinas) { disciplina in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(disciplina.sigla) - \(disciplina.nome)")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            if let prof = disciplina.professor, !prof.isEmpty {
                                Text("Prof: \(prof)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Faltas
                        let totalFaltas = disciplina.faltas.reduce(into: 0) { $0 += $1.quantidadeHoras }
                        Text("Faltas: \(totalFaltas) horas")
                            .font(.subheadline)
                        
                        // Notas
                        if disciplina.avaliacoes.isEmpty {
                            Text("Sem avaliações registradas.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(disciplina.avaliacoes.sorted(by: { $0.data < $1.data })) { avaliacao in
                                    HStack {
                                        Text("- \(avaliacao.titulo)")
                                            .font(.footnote)
                                        Spacer()
                                        Text(String(format: "Nota: %.1f (Peso: %.1f)", avaliacao.notaObtida, avaliacao.peso))
                                            .font(.footnote)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            .padding(.leading, 10)
                            
                            // Média Final
                            let media = calcularMediaPonderada(disciplina: disciplina)
                            HStack {
                                Spacer()
                                Text("Média Final:")
                                    .font(.subheadline)
                                    .bold()
                                Text(String(format: "%.1f", media))
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(corParaNota(media))
                            }
                            .padding(.top, 4)
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                    }
                }
                
                // Rodapé
                Spacer(minLength: 50)
                HStack {
                    Spacer()
                    Text("Gerado automaticamente pelo MedPlanner para macOS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(40)
        .frame(width: 595, height: 842, alignment: .topLeading) // A4 width/height
        .background(Color.white)
        // Fixed textColor logic here isn't great if user runs in Dark Mode, so 
        // we enforce light color scheme for the PDF.
        .environment(\.colorScheme, .light)
    }
    
    private func calcularMediaPonderada(disciplina: Disciplina) -> Double {
        if disciplina.avaliacoes.isEmpty { return 0.0 }
        var somaNotasPesos = 0.0
        var somaPesos = 0.0
        
        for av in disciplina.avaliacoes {
            somaNotasPesos += (av.notaObtida * av.peso)
            somaPesos += av.peso
        }
        
        if somaPesos == 0 { return 0.0 }
        return somaNotasPesos / somaPesos
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
