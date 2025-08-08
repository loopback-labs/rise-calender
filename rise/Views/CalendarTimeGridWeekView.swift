import SwiftUI

struct CalendarTimeGridWeekView: View {
  @ObserveInjection var inject
  let startOfWeek: Date
  let events: [CalendarEvent]
  let onSelectEvent: (CalendarEvent, CGPoint) -> Void

  private let hours: [Int] = Array(0...23)

  var body: some View {
    let minWidth = 7 * CalendarStyle.dayColumnMinWidth + 54 + 12 * 8
    let minHeight = 24 * CalendarStyle.hourRowHeight

    ScrollView([.vertical, .horizontal]) {
      VStack(spacing: 0) {
        // All-day events section
        AllDayEventsRow(startOfWeek: startOfWeek, events: events, onSelectEvent: onSelectEvent)
          .frame(height: 60)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)

        Divider()

        // Time grid section
        HStack(alignment: .top, spacing: 16) {
          HourGutter(hours: hours)
          // 7 day columns
          ForEach(0..<7, id: \.self) { col in
            let day = Calendar.current.date(byAdding: .day, value: col, to: startOfWeek)!
            VStack(spacing: 6) {
              DayHeader(date: day)
              DayColumn(day: day, events: eventsFor(day), onSelectEvent: onSelectEvent)
                .overlay(alignment: .topLeading) {
                  if day.isToday { NowIndicator(startOfDay: day) }
                }
            }
            .frame(minWidth: CalendarStyle.dayColumnMinWidth)
          }
        }
        .padding(12)
        .frame(minWidth: minWidth, minHeight: minHeight)
      }
    }
    .background(CalendarStyle.background)
    .enableInjection()
  }

  private func eventsFor(_ day: Date) -> [CalendarEvent] {
    let cal = Calendar.current
    return events.filter {
      cal.isDate($0.startDate, inSameDayAs: day) && !isAllDayEvent($0)
    }
  }

  private func isAllDayEvent(_ event: CalendarEvent) -> Bool {
    let cal = Calendar.current
    let startComponents = cal.dateComponents([.hour, .minute, .second], from: event.startDate)
    let endComponents = cal.dateComponents([.hour, .minute, .second], from: event.endDate)

    return (startComponents.hour == 0 && startComponents.minute == 0 && startComponents.second == 0)
      && (endComponents.hour == 0 && endComponents.minute == 0 && endComponents.second == 0)
  }
}

struct AllDayEventsRow: View {
  let startOfWeek: Date
  let events: [CalendarEvent]
  let onSelectEvent: (CalendarEvent, CGPoint) -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 16) {
      // All-day label
      Text("all-day")
        .font(.caption2.weight(.medium))
        .foregroundColor(.secondary)
        .frame(width: 54, alignment: .trailing)
        .padding(.top, 4)

      // Day columns for all-day events
      ForEach(0..<7, id: \.self) { col in
        let day = Calendar.current.date(byAdding: .day, value: col, to: startOfWeek)!
        AllDayColumn(day: day, events: allDayEventsFor(day), onSelectEvent: onSelectEvent)
          .frame(minWidth: CalendarStyle.dayColumnMinWidth)
      }
    }
  }

  private func allDayEventsFor(_ day: Date) -> [CalendarEvent] {
    let cal = Calendar.current
    return events.filter {
      cal.isDate($0.startDate, inSameDayAs: day) && isAllDayEvent($0)
    }
  }

  private func isAllDayEvent(_ event: CalendarEvent) -> Bool {
    let cal = Calendar.current
    let startComponents = cal.dateComponents([.hour, .minute, .second], from: event.startDate)
    let endComponents = cal.dateComponents([.hour, .minute, .second], from: event.endDate)

    return (startComponents.hour == 0 && startComponents.minute == 0 && startComponents.second == 0)
      && (endComponents.hour == 0 && endComponents.minute == 0 && endComponents.second == 0)
  }
}

struct AllDayColumn: View {
  let day: Date
  let events: [CalendarEvent]
  let onSelectEvent: (CalendarEvent, CGPoint) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      ForEach(events.prefix(3)) { event in
        AllDayEventBubble(event: event, onSelect: onSelectEvent)
      }
      if events.count > 3 {
        Text("+\(events.count - 3) more")
          .font(.caption2)
          .foregroundColor(.secondary)
          .padding(.horizontal, 4)
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

struct AllDayEventBubble: View {
  let event: CalendarEvent
  let onSelect: (CalendarEvent, CGPoint) -> Void
  @State private var isHovering = false

  var body: some View {
    Button(action: {
      // Get the current mouse position relative to the window
      let mouseLocation = NSEvent.mouseLocation
      if let window = NSApplication.shared.windows.first {
        let windowPoint = window.convertPoint(fromScreen: mouseLocation)
        onSelect(event, windowPoint)
      } else {
        onSelect(event, CGPoint(x: 100, y: 100))  // Fallback position
      }
    }) {
      HStack(spacing: 6) {
        Circle()
          .fill(Color(hex: event.colorHex ?? "#5E6AD2"))
          .frame(width: 8, height: 8)
        Text(event.title)
          .font(.caption)
          .lineLimit(1)
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(
        RoundedRectangle(cornerRadius: 4)
          .fill(Color(hex: event.colorHex ?? "#5E6AD2").opacity(isHovering ? 0.2 : 0.15))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 4)
          .stroke(Color(hex: event.colorHex ?? "#5E6AD2").opacity(0.4), lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
  }
}

private struct HourGutter: View {
  let hours: [Int]
  var body: some View {
    VStack(alignment: .trailing, spacing: 0) {
      ForEach(hours, id: \.self) { h in
        Text(hourLabel(h))
          .font(.caption2.weight(.medium))
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
        .font(.caption.weight(.medium))
        .foregroundColor(date.isToday ? .primary : .secondary)
      TodayBadge(date: date)
    }
    .frame(height: CalendarStyle.dayHeaderHeight)
    .frame(maxWidth: .infinity)
    .background(date.isToday ? CalendarStyle.todayBackground : .clear)
  }
}

private struct DayColumn: View {
  let day: Date
  let events: [CalendarEvent]
  let onSelectEvent: (CalendarEvent, CGPoint) -> Void

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
        let duration = max(endMinutes - startMinutes, 15)  // Minimum 15 minutes
        let eventHeight = CGFloat(duration) / 60.0 * CalendarStyle.hourRowHeight

        EventBubble(event: ev, onSelect: onSelectEvent)
          .frame(maxWidth: .infinity, maxHeight: eventHeight)
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

private struct EventBubble: View {
  let event: CalendarEvent
  let onSelect: (CalendarEvent, CGPoint) -> Void
  @State private var isHovering: Bool = false

  var body: some View {
    Button(action: {
      // Get the current mouse position relative to the window
      let mouseLocation = NSEvent.mouseLocation
      if let window = NSApplication.shared.windows.first {
        let windowPoint = window.convertPoint(fromScreen: mouseLocation)
        onSelect(event, windowPoint)
      } else {
        onSelect(event, CGPoint(x: 100, y: 100))  // Fallback position
      }
    }) {
      VStack(alignment: .leading, spacing: 2) {
        // Time range at the top
        Text(timeRangeText)
          .font(.caption2.weight(.semibold))
          .lineLimit(1)
          .foregroundColor(.primary)

        // Event title
        Text(event.title)
          .font(.caption)
          .lineLimit(1)
          .multilineTextAlignment(.leading)
          .foregroundColor(.primary)

        // Location (if available)
        if let location = event.location, !location.isEmpty {
          Text(location)
            .font(.caption2)
            .foregroundColor(.secondary)
            .lineLimit(1)
        }

        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .padding(.horizontal, 4)
      .padding(.vertical, 2)
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

  private var timeRangeText: String {
    let startTime = event.startDate.formatted(date: .omitted, time: .shortened)
    let endTime = event.endDate.formatted(date: .omitted, time: .shortened)
    return "\(startTime) - \(endTime)"
  }
}
