import SwiftUI

@main
struct RueckenFitApp: App {
    @State private var store = Store()
    @State private var celebration = Celebration()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(celebration)
        }
    }
}

struct RootView: View {
    @Environment(Store.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Heute", systemImage: "checkmark.square") }
            OverviewView()
                .tabItem { Label("Übersicht", systemImage: "calendar") }
            SettingsView()
                .tabItem { Label("Mehr", systemImage: "gearshape") }
        }
        .tint(Theme.green)
        .overlay { CelebrationOverlay() }
        .onChange(of: scenePhase) { _, phase in
            // Nach Mitternacht oder nach längerer Pause den Tag neu setzen
            if phase == .active { store.refreshToday() }
        }
    }
}
