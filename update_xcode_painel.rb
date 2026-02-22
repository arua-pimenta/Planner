require 'xcodeproj'

project_path = 'Planner.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

def get_group(project, path)
  group = project.main_group
  path.split('/').each do |name|
    group = group.groups.find { |g| g.name == name || g.path == name } || group.new_group(name, name)
  end
  group
end

# Adicionar os Views/Painel
painel_group = get_group(project, 'Planner/Views/Painel')
['PainelView.swift'].each do |file_name|
  file_path = "Planner/Views/Painel/#{file_name}"
  
  # Remove se ja existia e recria
  existing = painel_group.files.find { |f| f.path == file_name }
  painel_group.remove_reference(existing) if existing
  
  file_ref = painel_group.new_file(file_name)
  target.add_file_references([file_ref])
  puts "Adicionado #{file_name}"
end

project.save
puts "Projeto Xcode salvo e atualizado!"
