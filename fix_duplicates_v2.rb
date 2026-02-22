require 'xcodeproj'

project_path = '/Users/aruapimenta/Library/Mobile Documents/com~apple~CloudDocs/Apps, trabalhos e testes/Planner/Planner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

removed_count = 0

project.targets.each do |target|
  target.build_phases.each do |phase|
    if phase.isa == 'PBXSourcesBuildPhase'
      seen_paths = {}
      files_to_remove = []
      
      phase.files.each do |build_file|
        file_ref = build_file.file_ref
        next if file_ref.nil?
        
        path = file_ref.real_path.to_s
        # Ignorar se o path estiver vazio
        next if path.nil? || path.empty?

        if seen_paths[path]
          files_to_remove << build_file
          removed_count += 1
          puts "Removendo duplicata: #{path}"
        else
          seen_paths[path] = true
        end
      end
      
      files_to_remove.each do |bf|
        phase.remove_build_file(bf)
      end
    end
  end
end

project.save
puts "Total de arquivos duplicados removidos: #{removed_count}"
