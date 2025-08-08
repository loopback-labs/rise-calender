import AppKit
import SwiftUI

struct EventDetailView: View {
  @ObserveInjection var inject
  let event: CalendarEvent

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(event.title).font(.title3).bold()
      Text(
        "\(event.startDate.formatted(date: .abbreviated, time: .shortened)) - \(event.endDate.formatted(date: .abbreviated, time: .shortened))"
      )
      .foregroundColor(.secondary)
      if let location = event.location, !location.isEmpty {
        Label(location, systemImage: "mappin.and.ellipse")
          .labelStyle(.titleAndIcon)
      }
      if let url = event.meetingURL {
        Button(action: { NSWorkspace.shared.open(url) }) {
          Label("Join Meeting", systemImage: "video.fill")
        }
      }
      if let description = event.description, !description.isEmpty {
        ScrollView { Text(description).textSelection(.enabled) }.frame(maxHeight: 200)
      }
    }
    .padding(16)
    .frame(minWidth: 360)
    .background(CalendarStyle.panelBackground)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .enableInjection()
  }
}
