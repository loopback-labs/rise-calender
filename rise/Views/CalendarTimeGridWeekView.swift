import SwiftUI

struct CalendarTimeGridWeekView: View {
  @ObserveInjection var inject
  let startOfWeek: Date
  let events: [CalendarEvent]
  let onSelectEvent: (CalendarEvent, CGPoint) -> Void

  private let hours: [Int] = Array(0...23)

  var body: some View {
    GeometryReader { geometry in
      VStack(spacing: 0) {
        // All-day events section
        AllDayEventsRow(startOfWeek: startOfWeek, events: events, onSelectEvent: onSelectEvent)
          .frame(height: 72)
          .padding(.horizontal, 16)
          .padding(.vertical, 12)

        Divider()
          .padding(.horizontal, 16)

        // Time grid section - fills remaining space
        HStack(alignment: .top, spacing: 20) {
          HourGutter(hours: hours)
          // 7 day columns
          ForEach(0..<7, id: \.self) { col in
            let day = Calendar.current.date(byAdding: .day, value: col, to: startOfWeek)!
            VStack(spacing: 8) {
              DayHeader(date: day)
              DayColumn(day: day, events: eventsFor(day), onSelectEvent: onSelectEvent)
                .overlay(alignment: .topLeading) {
                  if day.isToday { NowIndicator(startOfDay: day) }
                }
            }
            .frame(maxWidth: .infinity)
            .layoutPriority(1)
          }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    HStack(alignment: .top, spacing: 20) {  // Increased spacing
      // All-day label
      Text("all-day")
        .font(.caption2.weight(.medium))
        .foregroundColor(.secondary)
        .frame(width: 60, alignment: .trailing)  // Increased width
        .padding(.top, 6)

      // Day columns for all-day events
      ForEach(0..<7, id: \.self) { col in
        let day = Calendar.current.date(byAdding: .day, value: col, to: startOfWeek)!
        AllDayColumn(day: day, events: allDayEventsFor(day), onSelectEvent: onSelectEvent)
          .frame(minWidth: CalendarStyle.dayColumnMinWidth, maxWidth: .infinity)
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
    VStack(alignment: .leading, spacing: 3) {  // Increased spacing
      ForEach(events.prefix(4)) { event in  // Show more events
        AllDayEventBubble(event: event, onSelect: onSelectEvent)
      }
      if events.count > 4 {
        Text("+\(events.count - 4) more")
          .font(.caption2.weight(.medium))
          .foregroundColor(.secondary)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
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
          .font(.caption.weight(.medium))  // Improved typography
          .lineLimit(1)
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 8)  // Increased padding
      .padding(.vertical, 4)  // Increased padding
      .background(
        RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
          .fill(Color(hex: event.colorHex ?? "#5E6AD2").opacity(isHovering ? 0.3 : 0.2))  // Better opacity
      )
      .overlay(
        RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
          .stroke(Color(hex: event.colorHex ?? "#5E6AD2").opacity(0.7), lineWidth: 0.5)  // Better border
      )
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
  }
}

struct HourGutter: View {
  let hours: [Int]
  var body: some View {
    VStack(alignment: .trailing, spacing: 0) {
      ForEach(hours, id: \.self) { h in
        Text(hourLabel(h))
          .font(.caption2.weight(.medium))
          .foregroundColor(.secondary)
          .frame(width: 60, height: CalendarStyle.hourRowHeight, alignment: .topTrailing)  // Increased width
          .padding(.trailing, 8)  // Added padding
      }
    }
    .background(CalendarStyle.panelBackground)
  }

  private func hourLabel(_ h: Int) -> String {
    let date = Calendar.current.date(bySettingHour: h, minute: 0, second: 0, of: Date()) ?? Date()
    return date.formatted(date: .omitted, time: .shortened)
  }
}

struct DayHeader: View {
  let date: Date
  var body: some View {
    VStack(spacing: 4) {  // Increased spacing
      Text(date, format: .dateTime.weekday(.abbreviated))
        .font(.caption2.weight(.semibold))  // Improved typography
        .foregroundColor(date.isToday ? .primary : .secondary)
      TodayBadge(date: date)
    }
    .frame(height: CalendarStyle.dayHeaderHeight)
    .frame(maxWidth: .infinity)
    .background(date.isToday ? CalendarStyle.todayBackground : .clear)
    .cornerRadius(6)  // Added corner radius
  }
}

struct DayColumn: View {
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
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func minutesSinceMidnight(_ date: Date) -> Int {
    let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
    return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
  }
}

struct EventBubble: View {
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
      VStack(alignment: .leading, spacing: 3) {  // Increased spacing
        // Time range at the top
        Text(timeRangeText)
          .font(.caption2.weight(.semibold))
          .lineLimit(1)
          .foregroundColor(.primary)

        // Event title
        Text(event.title)
          .font(.caption.weight(.medium))  // Improved typography
          .lineLimit(2)  // Allow 2 lines for better readability
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
      .padding(.horizontal, 6)  // Increased padding
      .padding(.vertical, 4)  // Increased padding
      .background(
        RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
          .fill(tint.opacity(isHovering ? 0.3 : 0.2))  // Better opacity
      )
      .overlay(
        RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
          .stroke(tint.opacity(0.7), lineWidth: 0.5)  // Better border
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
