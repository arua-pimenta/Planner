require 'xcodeproj'

project_path = 'Planner.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Helper function
def remove_duplicates_from_phase(phase)
  seen_paths = {}
  duplicates_removed = 0

  # Copiar o array pra iterar e deletar seguro
  phase.files.to_a.each do |build_file|
    file_ref = build_file.file_ref
    next unless file_ref
    
    path = file_ref.real_path.to_s rescue file_ref.path
    
    if seen_paths[path]
      phase.remove_build_file(build_file)
      duplicates_removed += 1
    else
      seen_paths[path] = true
    end
  end
  duplicates_removed
end

removed = remove_duplicates_from_phase(target.source_build_phase)

project.save
puts "Limpos #{removed} arquivos duplicados do Compile Sources"
