import AppKit
import SwiftUI

struct EventDetailView: View {
  @ObserveInjection var inject
  let event: CalendarEvent
  @Environment(\.dismiss) private var dismiss
  @FocusState private var isFocused: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Header with title and calendar indicator
      HStack(alignment: .top, spacing: 8) {
        Image(systemName: "calendar")
          .foregroundColor(.secondary)
          .font(.caption)
        Text(event.title)
          .font(.headline)
          .fontWeight(.medium)
        Spacer()
      }

      // Date and time
      VStack(alignment: .leading, spacing: 4) {
        Text(
          "\(event.startDate.formatted(date: .abbreviated, time: .shortened)) - \(event.endDate.formatted(date: .abbreviated, time: .shortened))"
        )
        .font(.subheadline)
        .foregroundColor(.secondary)
      }

      // Location (if available)
      if let location = event.location, !location.isEmpty {
        VStack(alignment: .leading, spacing: 4) {
          Label("Location", systemImage: "location")
            .font(.caption)
            .foregroundColor(.secondary)
          Text(location)
            .font(.subheadline)
        }
      }

      // Meeting URL button
      if let url = event.meetingURL {
        Button(action: {
          NSWorkspace.shared.open(url)
          dismiss()
        }) {
          Label("Join Meeting", systemImage: "video.fill")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
      }

      // Description (if available)
      if let description = event.description, !description.isEmpty {
        VStack(alignment: .leading, spacing: 4) {
          Label("Notes", systemImage: "note.text")
            .font(.caption)
            .foregroundColor(.secondary)
          ScrollView {
            Text(description)
              .font(.subheadline)
              .textSelection(.enabled)
          }
          .frame(maxHeight: 120)
        }
      }

      Spacer(minLength: 0)
    }
    .padding(20)
    .frame(width: 320, height: 280)
    .background(CalendarStyle.panelBackground)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    .focused($isFocused)
    .onAppear {
      isFocused = true
    }
    .onKeyPress(.escape) {
      dismiss()
      return .handled
    }
    .enableInjection()
  }
}
