import SwiftUI

struct EventDetailPopover: View {
  @ObserveInjection var inject
  let event: CalendarEvent
  let onDismiss: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Header
      HStack(spacing: CalendarStyle.spacingSmall) {
        Text("Event Details")
          .font(CalendarStyle.fontHeadline.weight(.semibold))
          .foregroundColor(.primary)

        Spacer()

        Button(action: onDismiss) {
          Image(systemName: "xmark")
            .foregroundColor(.secondary)
            .font(.system(size: 12, weight: .medium))
        }
        .buttonStyle(.borderless)
      }
      .padding(.horizontal, CalendarStyle.spacingLarge)
      .padding(.vertical, CalendarStyle.spacingMedium)
      .background(CalendarStyle.panelBackground)

      Divider()

      ScrollView {
        VStack(alignment: .leading, spacing: CalendarStyle.spacingMedium) {
          // Title + color
          HStack(spacing: CalendarStyle.spacingSmall) {
            Circle()
              .fill(Color(hex: event.colorHex ?? "#5E6AD2"))
              .frame(width: 12, height: 12)

            Text(event.title)
              .font(CalendarStyle.fontHeadline.weight(.medium))
              .foregroundColor(.primary)
              .lineLimit(3)
          }

          // Time
          VStack(alignment: .leading, spacing: CalendarStyle.spacingSmall) {
            Text("Time")
              .font(CalendarStyle.fontBody.weight(.medium))
              .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 4) {
              Text(event.startDate, format: .dateTime.weekday(.wide).month().day().hour().minute())
                .font(CalendarStyle.fontBody)
                .foregroundColor(.primary)
              Text("to " + event.endDate.formatted(date: .omitted, time: .shortened))
                .font(CalendarStyle.fontBody)
                .foregroundColor(.secondary)
            }
            .padding(CalendarStyle.spacingSmall)
            .background(
              RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
                .fill(CalendarStyle.panelBackground)
            )
          }

          // Location
          if let location = event.location, !location.isEmpty {
            VStack(alignment: .leading, spacing: CalendarStyle.spacingSmall) {
              Text("Location")
                .font(CalendarStyle.fontBody.weight(.medium))
                .foregroundColor(.primary)

              Text(location)
                .font(CalendarStyle.fontBody)
                .foregroundColor(.primary)
                .lineLimit(3)
                .padding(CalendarStyle.spacingSmall)
                .background(
                  RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
                    .fill(CalendarStyle.panelBackground)
                )
            }
          }

          // Description
          if let description = event.description, !description.isEmpty {
            VStack(alignment: .leading, spacing: CalendarStyle.spacingSmall) {
              Text("Description")
                .font(CalendarStyle.fontBody.weight(.medium))
                .foregroundColor(.primary)

              Text(description)
                .font(CalendarStyle.fontBody)
                .foregroundColor(.primary)
                .lineLimit(10)
                .padding(CalendarStyle.spacingSmall)
                .background(
                  RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
                    .fill(CalendarStyle.panelBackground)
                )
            }
          }

          // Meeting link
          if let meetingURL = event.meetingURL {
            VStack(alignment: .leading, spacing: CalendarStyle.spacingSmall) {
              Text("Meeting Link")
                .font(CalendarStyle.fontBody.weight(.medium))
                .foregroundColor(.primary)

              Button(action: {
                NSWorkspace.shared.open(meetingURL)
              }) {
                HStack(spacing: CalendarStyle.spacingSmall) {
                  Image(systemName: "video.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 14))

                  Text("Join Meeting")
                    .font(CalendarStyle.fontBody)
                    .foregroundColor(.accentColor)
                }
                .padding(CalendarStyle.spacingSmall)
                .background(
                  RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
                    .fill(CalendarStyle.panelBackground)
                )
              }
              .buttonStyle(.plain)
            }
          }
        }
        .padding(.horizontal, CalendarStyle.spacingLarge)
        .padding(.vertical, CalendarStyle.spacingMedium)
      }
    }
    .frame(width: 360)
    .background(CalendarStyle.background)
    .enableInjection()
  }
}
