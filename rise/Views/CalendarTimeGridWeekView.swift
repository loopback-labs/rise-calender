import SwiftUI

struct CalendarTimeGridWeekView: View {
  @ObserveInjection var inject
  let startOfWeek: Date
  let events: [CalendarEvent]
  let onSelectEvent: (CalendarEvent, CGPoint) -> Void

  private let hours: [Int] = Array(0...23)

  var body: some View {
    ScrollView([.vertical, .horizontal], showsIndicators: false) {
      VStack(spacing: 0) {
        GridWeekHeaderRow(startOfWeek: startOfWeek)
          .padding(.horizontal, CalendarStyle.spacingXLarge)
          .padding(.top, CalendarStyle.spacingLarge)

        // All-day events section
        AllDayEventsRow(startOfWeek: startOfWeek, events: events, onSelectEvent: onSelectEvent)
          .frame(height: 72)
          .padding(.horizontal, CalendarStyle.spacingXLarge)
          .padding(.vertical, CalendarStyle.spacingLarge)

        Divider()
          .padding(.horizontal, CalendarStyle.spacingXLarge)

        // Time grid section
        HStack(alignment: .top, spacing: 20) {
          GridHourGutter(hours: hours, includeHeaderSpacer: false)
          // 7 day columns
          ForEach(0..<7, id: \.self) { col in
            let day = Calendar.current.date(byAdding: .day, value: col, to: startOfWeek)!
            VStack(spacing: CalendarStyle.spacingMedium) {
              GridDayColumn(day: day, events: eventsFor(day), onSelectEvent: onSelectEvent)
                .overlay(alignment: .topLeading) {
                  if day.isToday { NowIndicator(startOfDay: day) }
                }
            }
            .frame(minWidth: CalendarStyle.dayColumnMinWidth, maxWidth: .infinity)
            .layoutPriority(1)
          }
        }
        .padding(CalendarStyle.spacingXLarge)
        .frame(
          minWidth: 7 * CalendarStyle.dayColumnMinWidth + 60 + 20 * 8 + 32,
          minHeight: 24 * CalendarStyle.hourRowHeight
        )
      }
      .frame(minWidth: 7 * CalendarStyle.dayColumnMinWidth + 60 + 20 * 8 + 32)
    }
    .background(CalendarStyle.background)
    .scrollIndicators(.hidden)
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
    HStack(alignment: .top, spacing: 20) {
      // All-day label
      Text("all-day")
        .font(CalendarStyle.fontCaption.weight(.medium))
        .foregroundColor(.secondary)
        .frame(width: 60, alignment: .trailing)
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
    VStack(alignment: .leading, spacing: 2) {
      ForEach(events) { event in
        GridAllDayEventBubble(event: event) {
          let mouseLocation = NSEvent.mouseLocation
          if let window = NSApplication.shared.windows.first {
            let windowPoint = window.convertPoint(fromScreen: mouseLocation)
            onSelectEvent(event, windowPoint)
          }
        }
      }
      Spacer(minLength: 0)
    }
  }
}

struct GridAllDayEventBubble: View {
  let event: CalendarEvent
  let onSelect: () -> Void
  @State private var isHovering = false

  var body: some View {
    Button(action: onSelect) {
      HStack(spacing: CalendarStyle.spacingSmall) {
        Circle()
          .fill(Color(hex: event.colorHex ?? "#5E6AD2"))
          .frame(width: CalendarStyle.iconSizeMedium, height: CalendarStyle.iconSizeMedium)

        Text(event.title)
          .font(CalendarStyle.fontCaption)
          .foregroundColor(.primary)
          .lineLimit(1)

        Spacer(minLength: 0)
      }
      .padding(.horizontal, CalendarStyle.spacingSmall)
      .padding(.vertical, 2)
      .background(
        RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
          .fill(Color(hex: event.colorHex ?? "#5E6AD2").opacity(isHovering ? 0.2 : 0.1))
      )
      .overlay(
        RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
          .stroke(Color(hex: event.colorHex ?? "#5E6AD2").opacity(0.6), lineWidth: 0.5)
      )
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
  }
}

struct GridHourGutter: View {
  let hours: [Int]
  var includeHeaderSpacer: Bool = true

  var body: some View {
    VStack(spacing: 0) {
      if includeHeaderSpacer {
        // Empty space for header alignment
        Rectangle()
          .fill(Color.clear)
          .frame(height: CalendarStyle.dayHeaderHeight)
      }

      // Hour labels
      ForEach(hours, id: \.self) { hour in
        Text(formatHour(hour))
          .font(CalendarStyle.fontCaption)
          .foregroundColor(.secondary)
          .frame(width: 60, height: CalendarStyle.hourRowHeight, alignment: .topTrailing)
          .background(CalendarStyle.panelBackground)
          .id("hour-\(hour)")  // Add ID for scrolling
      }
    }
  }

  private func formatHour(_ hour: Int) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h a"
    let date =
      Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
    return formatter.string(from: date).lowercased()
  }
}

// Header row spanning all day columns to match the week header style
struct GridWeekHeaderRow: View {
  let startOfWeek: Date

  var body: some View {
    HStack(alignment: .center, spacing: 20) {
      // Spacer matching the hour gutter width
      Rectangle()
        .fill(Color.clear)
        .frame(width: 60, height: CalendarStyle.dayHeaderHeight)

      ForEach(0..<7, id: \.self) { col in
        let day = Calendar.current.date(byAdding: .day, value: col, to: startOfWeek)!
        GridDayHeader(date: day)
          .frame(minWidth: CalendarStyle.dayColumnMinWidth, maxWidth: .infinity)
      }
    }
  }
}

struct GridDayHeader: View {
  let date: Date

  var body: some View {
    VStack(spacing: 2) {
      Text(date, format: .dateTime.weekday(.abbreviated))
        .font(CalendarStyle.fontCaption.weight(.medium))
        .foregroundColor(.secondary)

      Text(date, format: .dateTime.day())
        .font(CalendarStyle.fontCaption.weight(.semibold))
        .foregroundColor(date.isToday ? .white : .primary)
        .frame(width: 24, height: 24)
        .background(
          Circle()
            .fill(date.isToday ? Color.accentColor : Color.clear)
        )
    }
    .frame(height: CalendarStyle.dayHeaderHeight)
    .background(date.isToday ? CalendarStyle.todayBackground : .clear)
  }
}

struct GridDayColumn: View {
  let day: Date
  let events: [CalendarEvent]
  let onSelectEvent: (CalendarEvent, CGPoint) -> Void

  var body: some View {
    VStack(spacing: 0) {
      ForEach(0..<24, id: \.self) { hour in
        Rectangle()
          .fill(CalendarStyle.subtleGridFill)
          .frame(height: CalendarStyle.hourRowHeight)
          .overlay(Rectangle().fill(CalendarStyle.gridLine).frame(height: 0.5), alignment: .top)
      }
    }
    .overlay(alignment: .topLeading) {
      // Event overlays with collision-aware layout
      GeometryReader { proxy in
        let layout = layoutEvents(events: events)
        let columnSpacing: CGFloat = 4

        ForEach(Array(layout.enumerated()), id: \.element.event.id) { index, item in
          let width = max(0, proxy.size.width * item.widthFraction - columnSpacing)
          let x = proxy.size.width * item.xFraction + columnSpacing / 2

          GridEventBubble(event: item.event) {
            let mouseLocation = NSEvent.mouseLocation
            if let window = NSApplication.shared.windows.first {
              let windowPoint = window.convertPoint(fromScreen: mouseLocation)
              onSelectEvent(item.event, windowPoint)
            }
          }
          .frame(width: width)
          .offset(x: x)
        }
      }
    }
  }

  // MARK: - Layout
  private struct PositionedEvent {
    let event: CalendarEvent
    let columnIndex: Int
    let columnsInGroup: Int
    var widthFraction: CGFloat { 1 / CGFloat(max(columnsInGroup, 1)) }
    var xFraction: CGFloat { CGFloat(columnIndex) * widthFraction }
  }

  private func layoutEvents(events: [CalendarEvent]) -> [PositionedEvent] {
    // Sort events by start time
    let sorted = events.sorted { $0.startDate < $1.startDate }
    var positioned: [PositionedEvent] = []

    var group: [CalendarEvent] = []
    var groupMaxEnd: Date = .distantPast

    func flushGroup() {
      guard !group.isEmpty else { return }
      // Assign columns greedily
      var columnEndTimes: [Date] = []
      for ev in group {
        var placed = false
        for idx in 0..<columnEndTimes.count {
          if columnEndTimes[idx] <= ev.startDate {
            columnEndTimes[idx] = ev.endDate
            positioned.append(PositionedEvent(event: ev, columnIndex: idx, columnsInGroup: 0))
            placed = true
            break
          }
        }
        if !placed {
          columnEndTimes.append(ev.endDate)
          positioned.append(
            PositionedEvent(event: ev, columnIndex: columnEndTimes.count - 1, columnsInGroup: 0))
        }
      }
      // Normalize columnsInGroup
      let count = max(columnEndTimes.count, 1)
      for i in 0..<positioned.count {
        if group.contains(where: { $0.id == positioned[i].event.id }) {
          positioned[i] = PositionedEvent(
            event: positioned[i].event, columnIndex: positioned[i].columnIndex,
            columnsInGroup: count)
        }
      }
      group.removeAll()
      groupMaxEnd = .distantPast
    }

    for ev in sorted {
      if group.isEmpty {
        group = [ev]
        groupMaxEnd = ev.endDate
      } else if ev.startDate < groupMaxEnd {  // overlaps current group
        group.append(ev)
        if ev.endDate > groupMaxEnd { groupMaxEnd = ev.endDate }
      } else {
        flushGroup()
        group = [ev]
        groupMaxEnd = ev.endDate
      }
    }
    flushGroup()

    return positioned
  }
}

private struct GridEventBubble: View {
  let event: CalendarEvent
  let onSelect: () -> Void
  @State private var isHovering = false

  private var eventPosition: (top: CGFloat, height: CGFloat) {
    let cal = Calendar.current

    // Get the start and end times for the event on the current day
    let eventStart = event.startDate
    let eventEnd = event.endDate

    // Calculate start time in minutes from midnight
    let startComponents = cal.dateComponents([.hour, .minute], from: eventStart)
    let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)

    // Calculate end time in minutes from midnight
    let endComponents = cal.dateComponents([.hour, .minute], from: eventEnd)
    let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)

    // For multi-day events, clamp to the current day boundaries
    let clampedStartMinutes = max(0, startMinutes)
    let clampedEndMinutes = min(24 * 60, endMinutes)  // 24 hours * 60 minutes
    let duration = max(30, clampedEndMinutes - clampedStartMinutes)  // Minimum 30 minutes

    let top = CGFloat(clampedStartMinutes) / 60.0 * CalendarStyle.hourRowHeight
    let eventHeight = CGFloat(duration) / 60.0 * CalendarStyle.hourRowHeight

    return (top, eventHeight)
  }

  var body: some View {
    Button(action: onSelect) {
      VStack(alignment: .leading, spacing: 2) {
        Text(event.title)
          .font(.system(size: 11, weight: .semibold))
          .foregroundColor(.primary)
          .lineLimit(1)
          .minimumScaleFactor(0.8)

        if let location = event.location, !location.isEmpty {
          Text(location)
            .font(.system(size: 10))
            .foregroundColor(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }

        Spacer(minLength: 0)
      }
      .padding(.horizontal, 6)
      .padding(.vertical, 4)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .background(
        RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
          .fill(Color(hex: event.colorHex ?? "#5E6AD2").opacity(isHovering ? 0.2 : 0.1))
      )
      .overlay(
        RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
          .stroke(Color(hex: event.colorHex ?? "#5E6AD2").opacity(0.6), lineWidth: 0.5)
      )
    }
    .buttonStyle(.plain)
    .frame(height: eventPosition.height - 1)  // avoid touching grid line
    .offset(y: eventPosition.top + 0.5)  // center within the hour row
    .onHover { isHovering = $0 }
  }
}
