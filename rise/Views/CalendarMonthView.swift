import SwiftUI

struct CalendarMonthView: View {
  @ObserveInjection var inject
  let date: Date
  let events: [CalendarEvent]
  let onSelectEvent: (CalendarEvent, CGPoint) -> Void

  private var monthMetadata: (firstDay: Date, days: Int, firstWeekday: Int) {
    let cal = Calendar.current
    let comps = cal.dateComponents([.year, .month], from: date)
    let firstDay = cal.date(from: comps) ?? date
    let daysRange = cal.range(of: .day, in: .month, for: firstDay) ?? (1..<31)
    let weekday = cal.component(.weekday, from: firstDay)  // 1..7
    return (firstDay, daysRange.count, weekday)
  }

  var body: some View {
    let cal = Calendar.current
    let md = monthMetadata
    let leadingBlanks = md.firstWeekday - 1
    let totalCells = leadingBlanks + md.days
    let rows = Int(ceil(Double(totalCells) / 7.0))

    ScrollView([.vertical, .horizontal]) {
      VStack(spacing: 12) {
        LazyVGrid(
          columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 12
        ) {
          // Header row
          ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { d in
            Text(d)
              .font(.caption.weight(.medium))
              .foregroundColor(.secondary)
              .frame(maxWidth: .infinity, alignment: .center)
              .frame(height: 24)
          }

          // Calendar days
          ForEach(0..<totalCells, id: \.self) { cellIndex in
            if cellIndex < leadingBlanks || cellIndex >= totalCells {
              // Empty cell
              Rectangle()
                .fill(Color.clear)
                .frame(height: 100)
            } else {
              // Day cell
              let dayOffset = cellIndex - leadingBlanks
              let dayDate = cal.date(byAdding: .day, value: dayOffset, to: md.firstDay)!
              DayCell(date: dayDate, events: eventsFor(dayDate)) { ev, position in
                onSelectEvent(ev, position)
              }
              .frame(height: 100)
            }
          }
        }
        .frame(minWidth: 700, minHeight: 480)
      }
      .padding(12)
    }
    .enableInjection()
  }

  private func eventsFor(_ day: Date) -> [CalendarEvent] {
    let cal = Calendar.current
    return events.filter { cal.isDate($0.startDate, inSameDayAs: day) }
  }
}

private struct DayCell: View {
  let date: Date
  let events: [CalendarEvent]
  let onSelect: (CalendarEvent, CGPoint) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 6) {
        Text(date, format: .dateTime.weekday(.abbreviated))
          .font(.caption2)
          .foregroundColor(.secondary)
        TodayBadge(date: date)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      LazyVStack(alignment: .leading, spacing: 3) {
        ForEach(events.prefix(3)) { ev in
          EventButton(event: ev, onSelect: onSelect)
        }
        if events.count > 3 {
          Text("+\(events.count - 3) more").font(.caption2).foregroundColor(.secondary)
        }
      }
      Spacer(minLength: 0)
    }
    .padding(10)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(
      RoundedRectangle(cornerRadius: CalendarStyle.monthCellCornerRadius)
        .fill(date.isToday ? CalendarStyle.todayBackground : CalendarStyle.panelBackground)
    )
  }
}

private struct EventButton: View {
  let event: CalendarEvent
  let onSelect: (CalendarEvent, CGPoint) -> Void

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
        Circle().fill(Color(hex: event.colorHex ?? "#5E6AD2")).frame(width: 6, height: 6)
        Text(event.title).lineLimit(1).font(.caption)
      }
    }
    .buttonStyle(.plain)
  }
}

// Color(hex:) extension moved to Extensions/Color+Hex.swift
