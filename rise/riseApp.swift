//
//  riseApp.swift
//  rise
//
//  Created by Piyush Bhutoria on 08/08/25.
//

import SwiftUI

@main
struct riseApp: App {
  @StateObject private var preferencesManager = PreferencesManager()
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(preferencesManager)
    }
    .windowResizability(.contentSize)
    .defaultSize(width: 1200, height: 800)
    .windowStyle(.hiddenTitleBar)
    .commands {
      // Add Preferences command with standard Mac shortcut
      CommandGroup(after: .appInfo) {
        Button("Preferences...") {
          preferencesManager.showPreferences = true
        }
        .keyboardShortcut(",", modifiers: [.command])
      }
    }
    
    // Add Preferences window
    Settings {
      PreferencesView()
        .environmentObject(preferencesManager)
    }
  }
}

// Preferences manager to handle showing/hiding preferences
class PreferencesManager: ObservableObject {
  @Published var showPreferences = false
}
