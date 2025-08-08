import SwiftUI

struct CalendarTimeGridWeekView: View {
  @ObserveInjection var inject
  let startOfWeek: Date
  let events: [CalendarEvent]
  let onSelectEvent: (CalendarEvent) -> Void

  private let hours: [Int] = Array(0...23)

  var body: some View {
    let minWidth = 7 * CalendarStyle.dayColumnMinWidth + 54 + 12 * 8
    let minHeight = 24 * CalendarStyle.hourRowHeight

    ScrollView([.vertical, .horizontal]) {
      HStack(alignment: .top, spacing: 12) {
        HourGutter(hours: hours)
        // 7 day columns
        ForEach(0..<7, id: \.self) { col in
          let day = Calendar.current.date(byAdding: .day, value: col, to: startOfWeek)!
          VStack(spacing: 4) {
            DayHeader(date: day)
            DayColumn(day: day, events: eventsFor(day), onSelectEvent: onSelectEvent)
              .overlay(alignment: .topLeading) { if day.isToday { NowIndicator(startOfDay: day) } }
          }
          .frame(minWidth: CalendarStyle.dayColumnMinWidth)
        }
      }
      .padding(8)
      .frame(minWidth: minWidth, minHeight: minHeight)
    }
    .background(CalendarStyle.background)
    .enableInjection()
  }

  private func eventsFor(_ day: Date) -> [CalendarEvent] {
    let cal = Calendar.current
    return events.filter { cal.isDate($0.startDate, inSameDayAs: day) }
  }
}

private struct HourGutter: View {
  let hours: [Int]
  var body: some View {
    VStack(alignment: .trailing, spacing: 0) {
      ForEach(hours, id: \.self) { h in
        Text(hourLabel(h))
          .font(.caption2)
          .foregroundColor(.secondary)
          .frame(width: 54, height: CalendarStyle.hourRowHeight, alignment: .topTrailing)
      }
    }
    .background(CalendarStyle.panelBackground)
  }

  private func hourLabel(_ h: Int) -> String {
    let date = Calendar.current.date(bySettingHour: h, minute: 0, second: 0, of: Date()) ?? Date()
    return date.formatted(date: .omitted, time: .shortened)
  }
}

private struct DayHeader: View {
  let date: Date
  var body: some View {
    HStack(spacing: 6) {
      Text(date, format: .dateTime.weekday(.abbreviated))
        .font(.caption)
        .foregroundColor(date.isToday ? .primary : .secondary)
      TodayBadge(date: date)
    }
    .frame(height: CalendarStyle.dayHeaderHeight)
    .frame(maxWidth: .infinity)
    .background(date.isToday ? Color.accentColor.opacity(0.08) : .clear)
  }
}

private struct DayColumn: View {
  let day: Date
  let events: [CalendarEvent]
  let onSelectEvent: (CalendarEvent) -> Void

  var body: some View {
    ZStack(alignment: .topLeading) {
      // hour separators
      VStack(spacing: 0) {
        ForEach(0..<24, id: \.self) { _ in
          Rectangle()
            .fill(CalendarStyle.subtleGridFill)
            .frame(height: CalendarStyle.hourRowHeight)
            .overlay(Rectangle().fill(CalendarStyle.gridLine).frame(height: 0.5), alignment: .top)
        }
      }
      // events positioned by time
      ForEach(events) { ev in
        let startMinutes = minutesSinceMidnight(ev.startDate)
        let endMinutes = minutesSinceMidnight(ev.endDate)
        let top = CGFloat(startMinutes) / 60.0 * CalendarStyle.hourRowHeight
        let eventHeight = max(
          24, CGFloat(max(endMinutes - startMinutes, 30)) / 60.0 * CalendarStyle.hourRowHeight)
        EventBubble(event: ev, onSelect: onSelectEvent)
          .frame(maxWidth: .infinity, minHeight: eventHeight)
          .offset(y: top)
      }
    }
    .frame(maxWidth: .infinity, minHeight: 24 * CalendarStyle.hourRowHeight)
  }

  private func minutesSinceMidnight(_ date: Date) -> Int {
    let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
    return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
  }
}

extension CalendarTimeGridWeekView {
  fileprivate func hourLabel(_ h: Int) -> String {
    let date = Calendar.current.date(bySettingHour: h, minute: 0, second: 0, of: Date()) ?? Date()
    return date.formatted(date: .omitted, time: .shortened)
  }
}

private struct EventBubble: View {
  let event: CalendarEvent
  let onSelect: (CalendarEvent) -> Void
  @State private var isHovering: Bool = false

  var body: some View {
    Button(action: { onSelect(event) }) {
      HStack(alignment: .top, spacing: 8) {
        Rectangle()
          .fill(tint)
          .frame(width: 3)
          .cornerRadius(1.5)
        VStack(alignment: .leading, spacing: 2) {
          Text(event.startDate.formatted(date: .omitted, time: .shortened))
            .font(.caption2.weight(.semibold))
          Text(event.title)
            .font(.caption)
            .lineLimit(2)
          if let location = event.location, !location.isEmpty {
            Text(location)
              .font(.caption2)
              .foregroundColor(.secondary)
              .lineLimit(1)
          }
        }
        Spacer(minLength: 0)
      }
      .padding(6)
      .background(
        RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
          .fill(tint.opacity(isHovering ? 0.22 : 0.16))
      )
      .overlay(
        RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
          .stroke(tint.opacity(0.55), lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
  }

  private var tint: Color { Color(hex: event.colorHex ?? "#5E6AD2") }
}
