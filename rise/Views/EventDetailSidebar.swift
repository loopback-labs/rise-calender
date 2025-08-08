import SwiftUI

struct EventDetailSidebar: View {
  @ObserveInjection var inject
  let event: CalendarEvent?
  let onDismiss: () -> Void
  @StateObject private var vm = AppViewModel()
  @State private var showDeleteAlert = false

  var body: some View {
    VStack(spacing: 0) {
      // Header
      HStack {
        Text("Event Details")
          .font(CalendarStyle.fontHeadline.weight(.medium))
          .foregroundColor(.primary)

        Spacer()

        Button(action: onDismiss) {
          Image(systemName: "xmark")
            .foregroundColor(.secondary)
            .font(.system(size: 12, weight: .medium))
        }
        .buttonStyle(.borderless)
      }
      .padding(CalendarStyle.spacingLarge)
      .background(CalendarStyle.panelBackground)

      Divider()

      // Content
      if let event = event {
        ScrollView {
          VStack(alignment: .leading, spacing: CalendarStyle.spacingLarge) {
            // Event title and color
            VStack(alignment: .leading, spacing: CalendarStyle.spacingMedium) {
              HStack(spacing: CalendarStyle.spacingMedium) {
                Circle()
                  .fill(Color(hex: event.colorHex ?? "#5E6AD2"))
                  .frame(width: 12, height: 12)

                Text(event.title)
                  .font(CalendarStyle.fontHeadline.weight(.medium))
                  .foregroundColor(.primary)
                  .lineLimit(3)
              }
            }

            // Time information - Mac Calendar style
            VStack(alignment: .leading, spacing: CalendarStyle.spacingMedium) {
              Text("Time")
                .font(CalendarStyle.fontBody.weight(.medium))
                .foregroundColor(.primary)

              VStack(alignment: .leading, spacing: CalendarStyle.spacingSmall) {
                // Start time
                Text(event.startDate, format: .dateTime.weekday().month().day().hour().minute())
                  .font(CalendarStyle.fontBody)
                  .foregroundColor(.primary)

                // End time (only if different from start)
                if !Calendar.current.isDate(event.startDate, inSameDayAs: event.endDate)
                  || event.startDate != event.endDate
                {
                  Text(event.endDate, format: .dateTime.weekday().month().day().hour().minute())
                    .font(CalendarStyle.fontBody)
                    .foregroundColor(.primary)
                } else {
                  // Same day, show duration
                  let duration = event.endDate.timeIntervalSince(event.startDate)
                  let hours = Int(duration) / 3600
                  let minutes = Int(duration) % 3600 / 60

                  if hours > 0 {
                    Text("\(hours)h \(minutes > 0 ? "\(minutes)m" : "")")
                      .font(CalendarStyle.fontBody)
                      .foregroundColor(.secondary)
                  } else if minutes > 0 {
                    Text("\(minutes)m")
                      .font(CalendarStyle.fontBody)
                      .foregroundColor(.secondary)
                  }
                }
              }
              .padding(CalendarStyle.spacingMedium)
              .background(
                RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
                  .fill(CalendarStyle.panelBackground)
              )
            }

            // Location
            if let location = event.location, !location.isEmpty {
              VStack(alignment: .leading, spacing: CalendarStyle.spacingMedium) {
                Text("Location")
                  .font(CalendarStyle.fontBody.weight(.medium))
                  .foregroundColor(.primary)

                Text(location)
                  .font(CalendarStyle.fontBody)
                  .foregroundColor(.primary)
                  .lineLimit(3)
                  .padding(CalendarStyle.spacingMedium)
                  .background(
                    RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
                      .fill(CalendarStyle.panelBackground)
                  )
              }
            }

            // Description
            if let description = event.description, !description.isEmpty {
              VStack(alignment: .leading, spacing: CalendarStyle.spacingMedium) {
                Text("Description")
                  .font(CalendarStyle.fontBody.weight(.medium))
                  .foregroundColor(.primary)

                Text(description)
                  .font(CalendarStyle.fontBody)
                  .foregroundColor(.primary)
                  .lineLimit(10)
                  .padding(CalendarStyle.spacingMedium)
                  .background(
                    RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
                      .fill(CalendarStyle.panelBackground)
                  )
              }
            }

            // Meeting link
            if let meetingURL = event.meetingURL {
              VStack(alignment: .leading, spacing: CalendarStyle.spacingMedium) {
                Text("Meeting Link")
                  .font(CalendarStyle.fontBody.weight(.medium))
                  .foregroundColor(.primary)

                Button(action: {
                  NSWorkspace.shared.open(meetingURL)
                }) {
                  HStack(spacing: CalendarStyle.spacingMedium) {
                    Image(systemName: "video.fill")
                      .foregroundColor(.accentColor)
                      .font(.system(size: 14))

                    Text("Join Meeting")
                      .font(CalendarStyle.fontBody)
                      .foregroundColor(.accentColor)
                  }
                  .padding(CalendarStyle.spacingMedium)
                  .background(
                    RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
                      .fill(CalendarStyle.panelBackground)
                  )
                }
                .buttonStyle(.plain)
              }
            }

            Spacer(minLength: 0)
          }
          .padding(CalendarStyle.spacingLarge)
        }
      } else {
        // No event selected
        VStack(spacing: CalendarStyle.spacingLarge) {
          Image(systemName: "calendar")
            .font(.system(size: 48))
            .foregroundColor(.secondary)

          Text("No Event Selected")
            .font(CalendarStyle.fontHeadline)
            .foregroundColor(.secondary)

          Text("Select an event to view its details")
            .font(CalendarStyle.fontBody)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CalendarStyle.background)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(CalendarStyle.background)
    .enableInjection()
  }
}
