import SwiftUI
import SwiftData

struct ProfessorDetalheView: View {
    @Environment(\.openURL) var openURL
    
    var professor: Professor
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Cabecalho
                HStack(alignment: .top, spacing: 16) {
                    if let fotoData = professor.foto, let nsImage = NSImage(data: fotoData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(professor.nome.prefix(1).uppercased())
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline) {
                            if professor.titulo != .nenhum {
                                Text(professor.titulo.rawValue)
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                            Text(professor.nome)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        
                        if !professor.especialidade.isEmpty {
                            Text(professor.especialidade)
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.bottom, 8)
                
                // Acoes Rapidas
                HStack(spacing: 12) {
                    if !professor.whatsapp.isEmpty {
                        Button(action: {
                            abrirWhatsApp(numero: professor.whatsapp)
                        }) {
                            Label("WhatsApp", systemImage: "message.fill")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                    
                    if !professor.telefone.isEmpty {
                        Button(action: {
                            // No macOS telefonia nativa pode usar o FaceTime
                            if let url = URL(string: "facetime-audio://\(professor.telefone.filter("0123456789".contains))") {
                                openURL(url)
                            }
                        }) {
                            Label("Ligar", systemImage: "phone.fill")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if !professor.email.isEmpty {
                        Button(action: {
                            if let url = URL(string: "mailto:\(professor.email)") {
                                openURL(url)
                            }
                        }) {
                            Label("E-mail", systemImage: "envelope.fill")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Divider()
                
                // Informacoes Institucionais
                VStack(alignment: .leading, spacing: 16) {
                    Text("Informações Institucionais")
                        .font(.headline)
                    
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                        if !professor.departamento.isEmpty {
                            GridRow {
                                Text("Departamento:")
                                    .foregroundColor(.secondary)
                                Text(professor.departamento)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        if !professor.sala.isEmpty {
                            GridRow {
                                Text("Sala/Gabinete:")
                                    .foregroundColor(.secondary)
                                Text(professor.sala)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        if !professor.horarioAtendimento.isEmpty {
                            GridRow {
                                Text("Atendimento:")
                                    .foregroundColor(.secondary)
                                Text(professor.horarioAtendimento)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                
                // Disciplinas
                if !professor.disciplinas.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Disciplinas Ministradas")
                            .font(.headline)
                        
                        // Using a simple Wrap/HStack approach for chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(professor.disciplinas) { disciplina in
                                    DisciplinaChip(sigla: disciplina.sigla, corHexCode: disciplina.corHexCode)
                                }
                            }
                        }
                    }
                }
                
                // Anotacoes
                if !professor.anotacoes.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Anotações")
                            .font(.headline)
                        
                        Text(professor.anotacoes)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
            }
            .padding(32)
        }
    }
    
    private func abrirWhatsApp(numero: String) {
        let limpo = numero.filter("0123456789".contains)
        if let url = URL(string: "https://wa.me/\(limpo)") {
            openURL(url)
        }
    }
}
