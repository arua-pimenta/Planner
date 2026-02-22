import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var hasCompletedOnboarding: Bool
    @AppStorage("anosCurso") private var anosCurso: Int = 6
    @AppStorage("semestreAtivoGlobalId") private var semestreAtivoGlobalId = ""
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "cross.case.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Bem-vindo ao MedPlanner!")
                    .font(.largeTitle)
                    .bold()
                
                Text("Vamos preparar o seu ambiente de estudos.")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            GlassCard {
                VStack(alignment: .center, spacing: 16) {
                    Text("Qual a Duração do seu Curso?")
                        .font(.headline)
                    
                    Text("O sistema configurará todos os semestres automaticamente com base nos seus anos de faculdade.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Stepper("\(anosCurso) Anos (\(anosCurso * 2) Semestres)", value: $anosCurso, in: 1...10)
                        .frame(width: 250)
                        .padding(.vertical)
                }
                .padding()
            }
            
            Button(action: {
                prepararAmbiente()
                hasCompletedOnboarding = true
                dismiss()
            }) {
                Text("Começar Minha Jornada")
                    .font(.headline)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .controlSize(.large)
        }
        .padding(40)
        .frame(width: 600, height: 500)
    }
    
    private func prepararAmbiente() {
        let semestresQtd = anosCurso * 2
        let calendar = Calendar.current
        let dataBase = Date()
        
        let fetchDescriptor = FetchDescriptor<Semestre>()
        let atuais = (try? modelContext.fetch(fetchDescriptor)) ?? []
        guard atuais.isEmpty else { return }
        
        for i in 1...semestresQtd {
            let nome = "\(i)º Semestre"
            let dataInicio = calendar.date(byAdding: .month, value: (i - 1) * 6, to: dataBase) ?? dataBase
            let dataFim = calendar.date(byAdding: .month, value: 6, to: dataInicio) ?? dataBase
            let isAtivo = (i == 1)
            
            let novoSemestre = Semestre(nome: nome, dataInicio: dataInicio, dataFim: dataFim, isAtivo: isAtivo)
            modelContext.insert(novoSemestre)
            
            if isAtivo {
                semestreAtivoGlobalId = novoSemestre.id.uuidString
            }
        }
    }
}
