require 'xcodeproj'

project_path = 'Planner.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Remover referências duplicadas da fase "Compile Sources"
compile_sources = target.source_build_phase
files_seen = {}

compile_sources.files.each do |build_file|
  next unless build_file.file_ref
  
  # Identificar caminho
  file_path = build_file.file_ref.real_path rescue build_file.file_ref.path
  
  if files_seen[file_path]
    puts "Removendo duplicata em Compile Sources: #{file_path}"
    compile_sources.remove_build_file(build_file)
  else
    files_seen[file_path] = true
  end
end

project.save
puts "Limpeza de duplicatas Xcode concluída!"
