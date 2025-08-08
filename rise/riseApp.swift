//
//  riseApp.swift
//  rise
//
//  Created by Piyush Bhutoria on 08/08/25.
//

import SwiftData
import SwiftUI

@main
struct riseApp: App {
  let modelContainer: ModelContainer

  init() {
    do {
      modelContainer = try ModelContainer(for: Item.self)
    } catch {
      fatalError("Could not initialize ModelContainer")
    }
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .modelContainer(modelContainer)
    .windowResizability(.contentSize)
    .defaultSize(width: 1000, height: 700)
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
