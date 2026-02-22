require 'xcodeproj'

project_path = 'Planner.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Helper to find or create group
def get_group(project, path)
  group = project.main_group
  path.split('/').each do |name|
    group = group.groups.find { |g| g.name == name || g.path == name } || group.new_group(name, name)
  end
  group
end

# Adicionar os Models
models_group = get_group(project, 'Planner/Models')
['Professor.swift', 'Feriado.swift'].each do |file_name|
  file_path = "Planner/Models/#{file_name}"
  next if models_group.files.any? { |f| f.path == file_name }
  file_ref = models_group.new_file(file_name)
  target.add_file_references([file_ref])
  puts "Adicionado #{file_name}"
end

# Adicionar os Views/Professores
professores_group = get_group(project, 'Planner/Views/Professores')
['ProfessoresView.swift', 'NovoProfessorSheet.swift'].each do |file_name|
  file_path = "Planner/Views/Professores/#{file_name}"
  next if professores_group.files.any? { |f| f.path == file_name }
  file_ref = professores_group.new_file(file_name)
  target.add_file_references([file_ref])
  puts "Adicionado #{file_name}"
end

# Adicionar os Views/Agenda (FeriadosView)
agenda_group = get_group(project, 'Planner/Views/Agenda')
['FeriadosView.swift', 'NovoFeriadoSheet.swift'].each do |file_name|
  file_path = "Planner/Views/Agenda/#{file_name}"
  next if agenda_group.files.any? { |f| f.path == file_name }
  file_ref = agenda_group.new_file(file_name)
  target.add_file_references([file_ref])
  puts "Adicionado #{file_name}"
end

project.save
puts "Projeto Xcode salvo e atualizado!"
