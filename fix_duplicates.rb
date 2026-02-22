require 'xcodeproj'

project_path = "Planner.xcodeproj"
project = Xcodeproj::Project.open(project_path)

# Pega o primeiro target (normalmente o principal)
target = project.targets.first

source_build_phase = target.source_build_phase

# Agrupar arquivos por nome ou UUID para encontrar duplicatas
seen_files = {}
duplicates = []

source_build_phase.files.each do |build_file|
  next if build_file.file_ref.nil?
  
  file_path = build_file.file_ref.real_path.to_s
  
  if seen_files[file_path]
    duplicates << build_file
  else
    seen_files[file_path] = true
  end
end

puts "Removendo #{duplicates.count} arquivos duplicados da fase Compile Sources..."

duplicates.each do |build_file|
  puts "Removendo duplicata: #{build_file.file_ref.real_path}"
  source_build_phase.remove_build_file(build_file)
end

project.save
puts "Projeto salvo com sucesso!"
