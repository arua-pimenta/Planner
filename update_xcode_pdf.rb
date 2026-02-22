require 'xcodeproj'

project_path = '/Users/aruapimenta/Library/Mobile Documents/com~apple~CloudDocs/Apps, trabalhos e testes/Planner/Planner.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Criando Grupo PDF
app_group = project.main_group.find_subpath(File.join('Planner', 'Views'), true)
pdf_group = app_group.find_subpath('PDF', true)
pdf_group.set_source_tree('<group>')
pdf_group.set_path('PDF')

files_to_add = [
  'BoletimPDFView.swift',
  'PDFExporter.swift'
]

files_to_add.each do |file_name|
  file_path = "Planner/Views/PDF/#{file_name}"
  file_ref = pdf_group.find_file_by_path(file_name) || pdf_group.new_file(file_name)
  
  unless target.source_build_phase.files_references.include?(file_ref)
    build_file = target.source_build_phase.add_file_reference(file_ref)
    puts "Added #{file_name} to build phase"
  end
end

project.save
puts "Xcode project updated successfully with PDF views!"
