import SwiftUI
import SwiftData
import PhotosUI

struct NovoProfessorSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var professorToEdit: Professor?
    
    @State private var nome = ""
    @State private var titulo: TituloProfessor = .nenhum
    @State private var especialidade = ""
    @State private var departamento = ""
    @State private var email = ""
    @State private var telefone = ""
    @State private var whatsapp = ""
    @State private var horarioAtendimento = ""
    @State private var sala = ""
    @State private var anotacoes = ""
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var foto: Data?
    
    init(professorToEdit: Professor? = nil) {
        self.professorToEdit = professorToEdit
        _nome = State(initialValue: professorToEdit?.nome ?? "")
        _titulo = State(initialValue: professorToEdit?.titulo ?? .nenhum)
        _especialidade = State(initialValue: professorToEdit?.especialidade ?? "")
        _departamento = State(initialValue: professorToEdit?.departamento ?? "")
        _email = State(initialValue: professorToEdit?.email ?? "")
        _telefone = State(initialValue: professorToEdit?.telefone ?? "")
        _whatsapp = State(initialValue: professorToEdit?.whatsapp ?? "")
        _horarioAtendimento = State(initialValue: professorToEdit?.horarioAtendimento ?? "")
        _sala = State(initialValue: professorToEdit?.sala ?? "")
        _anotacoes = State(initialValue: professorToEdit?.anotacoes ?? "")
        _foto = State(initialValue: professorToEdit?.foto)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Identificação") {
                    HStack(alignment: .top, spacing: 16) {
                        VStack {
                            if let fotoData = foto, let nsImage = NSImage(data: fotoData) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                    .overlay(Image(systemName: "person.fill").foregroundColor(.secondary).font(.largeTitle))
                            }
                            
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                                Text("Alterar Foto")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                            .onChange(of: selectedPhotoItem) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                        foto = data
                                    }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Nome do Docente", text: $nome)
                            Picker("Título", selection: $titulo) {
                                ForEach(TituloProfessor.allCases, id: \.self) { t in
                                    Text(t.rawValue).tag(t)
                                }
                            }
                            TextField("Especialidade", text: $especialidade)
                        }
                    }
                }
                
                Section("Contato") {
                    TextField("E-mail", text: $email)
                    TextField("Telefone", text: $telefone)
                    TextField("WhatsApp", text: $whatsapp)
                }
                
                Section("Institucional") {
                    TextField("Departamento / Instituto", text: $departamento)
                    TextField("Sala / Gabinete", text: $sala)
                    TextField("Horário de Atendimento", text: $horarioAtendimento)
                }
                
                Section("Anotações") {
                    TextEditor(text: $anotacoes)
                        .frame(minHeight: 80)
                }
            }
            .padding()
            .frame(width: 500, height: 600)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(professorToEdit == nil ? "Salvar" : "Atualizar") {
                        salvarProfessor()
                    }
                    .disabled(nome.isEmpty)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    private func salvarProfessor() {
        if let edit = professorToEdit {
            edit.nome = nome
            edit.titulo = titulo
            edit.especialidade = especialidade
            edit.email = email
            edit.telefone = telefone
            edit.whatsapp = whatsapp
            edit.horarioAtendimento = horarioAtendimento
            edit.sala = sala
            edit.departamento = departamento
            edit.anotacoes = anotacoes
            edit.foto = foto
        } else {
            let novo = Professor(nome: nome, titulo: titulo, especialidade: especialidade, departamento: departamento, email: email, telefone: telefone, whatsapp: whatsapp, horarioAtendimento: horarioAtendimento, sala: sala, anotacoes: anotacoes, foto: foto)
            modelContext.insert(novo)
        }
        dismiss()
    }
}
