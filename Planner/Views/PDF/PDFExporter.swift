import SwiftUI
import AppKit

@MainActor
final class PDFExporter {
    static func generateAndSaveBoletimPDF(disciplinas: [Disciplina]) {
        let viewToRender = BoletimPDFView(disciplinas: disciplinas)
        let renderer = ImageRenderer(content: viewToRender)
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "Boletim_MedPlanner_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).pdf"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                renderer.render { size, context in
                    // Tamanho mágico do A4
                    var box = CGRect(x: 0, y: 0, width: 595, height: 842)
                    guard let pdfContext = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
                    
                    // Inicia o contexto da página
                    pdfContext.beginPDFPage(nil)
                    
                    // Ajusta escala caso houvesse margens (neste caso 1.0)
                    pdfContext.translateBy(x: 0, y: 0)
                    pdfContext.scaleBy(x: 1.0, y: 1.0)
                    
                    // Desenha o SwiftUI
                    context(pdfContext)
                    
                    pdfContext.endPDFPage()
                    pdfContext.closePDF()
                }
                
                // Opcional: Abrir o PDF gerado
                NSWorkspace.shared.open(url)
            }
        }
    }
}
