//
//  riseApp.swift
//  rise
//
//  Created by Piyush Bhutoria on 08/08/25.
//

import SwiftUI

@main
struct riseApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .windowResizability(.contentSize)
    .defaultSize(width: 1200, height: 800)
    .windowStyle(.hiddenTitleBar)
    .commands {
      // Add custom menu commands for better UX
      CommandGroup(replacing: .newItem) {
        Button("New Window") {
          NSApplication.shared.sendAction(
            #selector(NSApplication.newWindowForTab(_:)), to: nil, from: nil)
        }
        .keyboardShortcut("n", modifiers: [.command])
      }
    }
  }
}
