import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ConfiguracoesView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appBaseDirectory") private var appBaseDirectory = ""
    @AppStorage("semestreAtivoGlobalId") private var semestreAtivoGlobalId = ""
    @AppStorage("anosCurso") private var anosCurso: Int = 6
    
    // Novas configurações institucionais v1.3.6
    @AppStorage("escalaNotas") private var escalaNotas: Double = 100.0
    @AppStorage("mediaGlobalAprovacao") private var mediaGlobalAprovacao: Double = 60.0
    @AppStorage("presencaGlobalPadrao") private var presencaGlobalPadrao: Double = 75.0
    
    var body: some View {
        TabView {
            abaGeral
                .tabItem {
                    Label("Geral", systemImage: "gearshape")
                }
            
            abaInstitucional
                .tabItem {
                    Label("Institucional", systemImage: "building.columns")
                }
            
            abaDados
                .tabItem {
                    Label("Dados e Backup", systemImage: "externaldrive")
                }
        }
        .padding()
        .frame(minWidth: 550, minHeight: 450)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var abaGeral: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Configurações Gerais")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Estrutura do Curso")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Gere os semestres do seu curso automaticamente. Insira a duração em anos e o sistema criará os períodos (ex: 1º ao 12º Semestre).")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            
                        HStack {
                            Stepper("Duração: \(anosCurso) Anos (\(anosCurso * 2) Semestres)", value: $anosCurso, in: 1...10)
                                .frame(width: 300)
                                .onChange(of: anosCurso) { _, novoValor in
                                    sincronizarSemestres(novoAnos: novoValor)
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Armazenamento Local")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Selecione onde o MedPlanner deve salvar arquivos anexos pesados (como PDFs, slides e imagens). Você pode escolher qualquer pasta no seu Mac ou no iCloud Drive.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Diretório Atual:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(appBaseDirectory.isEmpty ? "Padrão de Sistema (Container)" : appBaseDirectory)
                                    .font(.body)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .padding(8)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(6)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                selecionarDiretorio()
                            }) {
                                Text("Alterar Diretório")
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(24)
        }
    }
    
    private var abaInstitucional: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Cálculos Acadêmicos")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sistema de Notas e Aprovação")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Defina as métricas institucionais usadas pela sua universidade para calcular notas e alertar sobre possíveis reprovações.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        Grid(alignment: .leading, horizontalSpacing: 32, verticalSpacing: 16) {
                            GridRow {
                                Text("Escala Máxima de Notas:")
                                    .fontWeight(.medium)
                                
                                HStack {
                                    TextField("Ex: 100", value: $escalaNotas, format: .number)
                                        .frame(width: 80)
                                        .textFieldStyle(.roundedBorder)
                                    Text("pontos")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            GridRow {
                                Text("Média Global de Aprovação:")
                                    .fontWeight(.medium)
                                
                                HStack {
                                    TextField("Ex: 60", value: $mediaGlobalAprovacao, format: .number)
                                        .frame(width: 80)
                                        .textFieldStyle(.roundedBorder)
                                    Text("pontos/nota mínima")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            GridRow {
                                Text("Frequência Mínima Exigida:")
                                    .fontWeight(.medium)
                                
                                HStack {
                                    TextField("Ex: 75", value: $presencaGlobalPadrao, format: .number)
                                        .frame(width: 80)
                                        .textFieldStyle(.roundedBorder)
                                    Text("% de presença")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(24)
        }
    }
    
    private var abaDados: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Ecossistema & Dados")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Exportação e Backups")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Exporte seus dados para um arquivo JSON estruturado ou importe um backup anterior. Note que importar um backup adicionará ou substituirá os dados lidos do arquivo.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                BackupManager.shared.exportData(context: modelContext)
                            }) {
                                Label("Exportar Backup em JSON", systemImage: "square.and.arrow.up")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            
                            Button(action: {
                                BackupManager.shared.importData(context: modelContext)
                            }) {
                                Label("Restaurar de um Backup Importado", systemImage: "square.and.arrow.down")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(24)
        }
    }
    
    // Funções utilitárias
    
    private func selecionarDiretorio() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Selecione a pasta raiz do MedPlanner"
        panel.prompt = "Selecionar Pasta"
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                appBaseDirectory = url.path
            }
        }
    }
    
    private func sincronizarSemestres(novoAnos: Int) {
        let semestresQtd = novoAnos * 2
        let calendar = Calendar.current
        let dataBase = Date()
        
        let fetchDescriptor = FetchDescriptor<Semestre>()
        let atuais = (try? modelContext.fetch(fetchDescriptor)) ?? []
        let countAtual = atuais.count
        
        if semestresQtd > countAtual {
            for i in (countAtual + 1)...semestresQtd {
                let nome = "\(i)º Semestre"
                let dataInicio = calendar.date(byAdding: .month, value: (i - 1) * 6, to: dataBase) ?? dataBase
                let dataFim = calendar.date(byAdding: .month, value: 6, to: dataInicio) ?? dataBase
                let isAtivo = (countAtual == 0 && i == 1)
                
                let novoSemestre = Semestre(nome: nome, dataInicio: dataInicio, dataFim: dataFim, isAtivo: isAtivo)
                modelContext.insert(novoSemestre)
                
                if isAtivo && semestreAtivoGlobalId.isEmpty {
                    semestreAtivoGlobalId = novoSemestre.id.uuidString
                }
            }
        }
    }
}
