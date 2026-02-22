import SwiftUI
import SwiftData

struct FeriadosView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Feriado.data) private var feriados: [Feriado]
    
    @State private var showingNovoFeriado = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(feriados) { feriado in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(feriado.nome)
                                .font(.headline)
                            
                            HStack {
                                Text(feriado.data.formatted(date: .long, time: .omitted))
                                
                                if feriado.recorrente {
                                    Image(systemName: "repeat")
                                        .foregroundColor(.blue)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            
                            HStack {
                                Text(feriado.tipo.rawValue)
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                                
                                if feriado.bloqueiaAulas {
                                    Text("Bloqueia Aulas")
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .cornerRadius(4)
                                }
                            }
                        }
                        Spacer()
                        
                        if NSCalendar.current.isDateInToday(feriado.data) {
                            StatusBadge(status: .hoje)
                        }
                    }
                    .padding(.vertical, 4)
                    .contextMenu {
                        Button("Apagar", role: .destructive) {
                            apagarFeriado(feriado)
                        }
                    }
                }
                .onDelete(perform: apagarLista)
            }
            .listStyle(.inset)
            .navigationTitle("Feriados Locais")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: {
                            importarFeriadosParaguai()
                        }) {
                            Label("Importar Feriados do Paraguai", systemImage: "arrow.down.doc")
                        }
                        
                        Divider()
                        
                        Button(action: {
                            showingNovoFeriado = true
                        }) {
                            Label("Novo Feriado", systemImage: "plus")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingNovoFeriado) {
                NovoFeriadoSheet()
            }
        }
    }
    
    private func apagarLista(offsets: IndexSet) {
        let sorted = feriados.sorted(by: { $0.data < $1.data })
        for index in offsets {
            modelContext.delete(sorted[index])
        }
    }
    
    private func apagarFeriado(_ feriado: Feriado) {
        modelContext.delete(feriado)
    }
    
    private func importarFeriadosParaguai() {
        let feriadosNacionais = [
            ("Ano Novo", "01-01"),
            ("Dia dos Heróis", "03-01"),
            ("Dia do Trabalhador", "05-01"),
            ("Independência do Paraguai", "05-14"),
            ("Independência do Paraguai (Dia das Mães)", "05-15"),
            ("Paz do Chaco", "06-12"),
            ("Fundação de Assunção", "08-15"),
            ("Batalha de Boquerón", "09-29"),
            ("Dia da Virgem de Caacupé", "12-08"),
            ("Natal", "12-25")
        ]
        
        // Feriados Móveis (Ex: 2025 aprox) ou Feriados Fixos serão inseridos no ano atual
        let currentYear = Calendar.current.component(.year, from: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        for f in feriadosNacionais {
            let dateStr = "\(currentYear)-\(f.1)"
            if let date = formatter.date(from: dateStr) {
                // Checar duplicatas pelo Nome e Dia para não encher o banco de dados caso clique várias vezes
                let exists = feriados.contains { Calendar.current.isDate($0.data, inSameDayAs: date) && $0.nome == f.0 }
                if !exists {
                    let novo = Feriado(nome: f.0, data: date, tipo: .nacional, recorrente: true, bloqueiaAulas: true)
                    modelContext.insert(novo)
                }
            }
        }
    }
}
