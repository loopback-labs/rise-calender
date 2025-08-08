import SwiftUI

struct CalendarWeekView: View {
  @ObserveInjection var inject
  let startOfWeek: Date
  let events: [CalendarEvent]
  let onSelectEvent: (CalendarEvent, CGPoint) -> Void

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: CalendarStyle.spacingLarge) {
        ForEach(0..<7, id: \.self) { dayOffset in
          let day = Calendar.current.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
          DaySection(
            date: day,
            events: eventsFor(day),
            onSelectEvent: onSelectEvent
          )
        }
      }
      .padding(CalendarStyle.spacingXLarge)
    }
    .background(CalendarStyle.background)
    .enableInjection()
  }

  private func eventsFor(_ day: Date) -> [CalendarEvent] {
    let cal = Calendar.current
    return events.filter { cal.isDate($0.startDate, inSameDayAs: day) }
      .sorted { $0.startDate < $1.startDate }
  }
}

private struct DaySection: View {
  let date: Date
  let events: [CalendarEvent]
  let onSelectEvent: (CalendarEvent, CGPoint) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: CalendarStyle.spacingMedium) {
      // Day header
      HStack {
        Text(date, format: .dateTime.weekday(.wide))
          .font(CalendarStyle.fontHeadline.weight(.medium))
          .foregroundColor(.primary)

        Text(date, format: .dateTime.month().day())
          .font(CalendarStyle.fontBody)
          .foregroundColor(.secondary)

        if date.isToday {
          Text("Today")
            .font(CalendarStyle.fontCaption.weight(.medium))
            .padding(.horizontal, CalendarStyle.spacingMedium)
            .padding(.vertical, CalendarStyle.spacingSmall)
            .background(
              RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
                .fill(Color.accentColor)
            )
            .foregroundColor(.white)
        }

        Spacer()
      }

      // Events
      if events.isEmpty {
        Text("No events")
          .font(CalendarStyle.fontBody)
          .foregroundColor(.secondary)
          .padding(.vertical, CalendarStyle.spacingLarge)
      } else {
        LazyVStack(alignment: .leading, spacing: CalendarStyle.spacingMedium) {
          ForEach(events) { event in
            WeekEventRow(event: event) {
              let mouseLocation = NSEvent.mouseLocation
              if let window = NSApplication.shared.windows.first {
                let windowPoint = window.convertPoint(fromScreen: mouseLocation)
                onSelectEvent(event, windowPoint)
              }
            }
          }
        }
      }
    }
    .padding(CalendarStyle.spacingLarge)
    .background(
      RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
        .fill(CalendarStyle.panelBackground)
    )
  }
}

private struct WeekEventRow: View {
  let event: CalendarEvent
  let onSelect: () -> Void
  @State private var isHovering = false

  var body: some View {
    Button(action: onSelect) {
      HStack(spacing: CalendarStyle.spacingMedium) {
        // Time
        VStack(alignment: .leading, spacing: CalendarStyle.spacingSmall) {
          Text(event.startDate, format: .dateTime.hour().minute())
            .font(CalendarStyle.fontBody.weight(.medium))
            .foregroundColor(.primary)

          Text(event.endDate, format: .dateTime.hour().minute())
            .font(CalendarStyle.fontCaption)
            .foregroundColor(.secondary)
        }
        .frame(width: 60, alignment: .leading)

        // Color indicator
        Circle()
          .fill(Color(hex: event.colorHex ?? "#5E6AD2"))
          .frame(width: CalendarStyle.iconSizeMedium, height: CalendarStyle.iconSizeMedium)

        // Event details
        VStack(alignment: .leading, spacing: CalendarStyle.spacingSmall) {
          Text(event.title)
            .font(CalendarStyle.fontBody.weight(.medium))
            .foregroundColor(.primary)
            .lineLimit(2)

          if let location = event.location, !location.isEmpty {
            Text(location)
              .font(CalendarStyle.fontCaption)
              .foregroundColor(.secondary)
              .lineLimit(1)
          }

          if let description = event.description, !description.isEmpty {
            Text(description)
              .font(CalendarStyle.fontCaption)
              .foregroundColor(.secondary)
              .lineLimit(3)
          }
        }

        Spacer()
      }
      .padding(CalendarStyle.spacingLarge)
      .background(
        RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
          .fill(isHovering ? CalendarStyle.hoverBackground : Color.clear)
      )
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
  }
}
