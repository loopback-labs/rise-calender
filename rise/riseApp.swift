import SwiftUI

@main
struct riseApp: App {
  @StateObject private var appVM = AppViewModel()
  var body: some Scene {
    WindowGroup {
      ContentView(vm: appVM)
    }
    .windowResizability(.automatic)
    .defaultSize(width: 1200, height: 800)
    .windowToolbarStyle(.unifiedCompact)

    // Add Preferences window - this automatically provides ⌘+, functionality
    Settings { PreferencesView(vm: appVM) }
  }
}
