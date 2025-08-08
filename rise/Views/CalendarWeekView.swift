import SwiftUI

struct CalendarWeekView: View {
  @ObserveInjection var inject
  let startOfWeek: Date
  let events: [CalendarEvent]
  let onSelectEvent: (CalendarEvent) -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        Text(weekRangeTitle)
          .font(.headline)
          .foregroundColor(.secondary)
          .padding(.horizontal, 8)

        ForEach(0..<7, id: \.self) { i in
          if let day = Calendar.current.date(byAdding: .day, value: i, to: startOfWeek) {
            DaySection(
              day: day,
              events: eventsFor(day),
              onSelectEvent: onSelectEvent
            )
          }
          if i < 6 {  // Don't add divider after the last day
            Divider()
              .padding(.horizontal, 8)
          }
        }
      }
      .padding(.vertical, 8)
    }
    .enableInjection()
  }

  private func eventsFor(_ day: Date) -> [CalendarEvent] {
    let cal = Calendar.current
    return events.filter { cal.isDate($0.startDate, inSameDayAs: day) }
  }
}

extension CalendarWeekView {
  fileprivate var weekRangeTitle: String {
    let end = Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) ?? startOfWeek
    let df = DateFormatter()
    df.dateFormat = "MMM d"
    return "\(df.string(from: startOfWeek)) – \(df.string(from: end))"
  }
}

private struct DaySection: View {
  let day: Date
  let events: [CalendarEvent]
  let onSelectEvent: (CalendarEvent) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 6) {
        Text(day, format: .dateTime.weekday(.wide))
          .font(.subheadline)
          .foregroundColor(.secondary)
        TodayBadge(date: day)
      }
      .padding(.horizontal, 8)

      if events.isEmpty {
        Text("No events")
          .foregroundColor(.secondary)
          .font(.caption)
          .padding(.horizontal, 8)
      } else {
        ForEach(events) { event in
          WeekEventRow(event: event, onSelect: onSelectEvent)
        }
      }
    }
    .padding(.vertical, 6)
  }
}

private struct WeekEventRow: View {
  let event: CalendarEvent
  let onSelect: (CalendarEvent) -> Void

  var body: some View {
    Button(action: { onSelect(event) }) {
      HStack(spacing: 8) {
        Circle().fill(Color(hex: event.colorHex ?? "#5E6AD2")).frame(width: 8, height: 8)
        VStack(alignment: .leading, spacing: 2) {
          Text(titleText)
            .lineLimit(1)
            .font(.body)
          if let location = event.location, !location.isEmpty {
            Text(location)
              .lineLimit(1)
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
        Spacer()
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(
        RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
          .fill(CalendarStyle.panelBackground)
      )
      .padding(.horizontal, 8)
    }
    .buttonStyle(.plain)
  }

  private var titleText: String {
    let time = event.startDate.formatted(date: .omitted, time: .shortened)
    return "\(time) - \(event.title)"
  }
}
