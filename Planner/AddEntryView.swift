import SwiftUI

struct AddEntryView: View {
    var body: some View {
        Color.black
            .ignoresSafeArea()
            .onAppear {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            }
    }
}
