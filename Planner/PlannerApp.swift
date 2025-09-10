import SwiftUI

@main
struct PlannerApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState) // ✅ inject here
                .preferredColorScheme(.dark)
                .tint(.white)
        }
    }
}
