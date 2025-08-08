import SwiftUI

struct CalendarMonthView: View {
  @ObserveInjection var inject
  let date: Date
  let events: [CalendarEvent]
  let onSelectEvent: (CalendarEvent, CGPoint) -> Void
  let onNavigateMonth: ((Int) -> Void)?  // Callback for month navigation

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

    VStack(spacing: 0) {
      // Calendar grid - fixed layout that fills the window
      LazyVGrid(
        columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
        spacing: 0
      ) {
        // Header row with weekday labels
        ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
          Text(day)
            .font(.caption2.weight(.semibold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: 32)
            .background(CalendarStyle.panelBackground)
        }

        // Calendar days - fixed height grid
        ForEach(0..<totalCells, id: \.self) { cellIndex in
          if cellIndex < leadingBlanks {
            // Empty cell for leading blanks
            Rectangle()
              .fill(Color.clear)
              .frame(maxHeight: .infinity)
          } else {
            // Day cell
            let dayOffset = cellIndex - leadingBlanks
            let dayDate = cal.date(byAdding: .day, value: dayOffset, to: md.firstDay)!
            DayCell(date: dayDate, events: eventsFor(dayDate)) { ev, position in
              onSelectEvent(ev, position)
            }
            .frame(maxHeight: .infinity)
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(CalendarStyle.background)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(CalendarStyle.background)
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
  @State private var showOverflowPopover = false
  @State private var overflowPopoverPosition: CGPoint = .zero

  // Maximum number of events to show before overflow
  private let maxVisibleEvents = 4

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Day header
      HStack {
        Text(date, format: .dateTime.day())
          .font(.caption2.weight(.medium))
          .foregroundColor(date.isToday ? .white : .primary)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(
            Circle()
              .fill(date.isToday ? Color.accentColor : Color.clear)
          )

        Spacer()
      }
      .frame(height: 28)
      .padding(.horizontal, 8)
      .padding(.top, 4)

      // Events section with fixed height
      VStack(alignment: .leading, spacing: 1) {
        ForEach(Array(events.prefix(maxVisibleEvents).enumerated()), id: \.element.id) {
          index, event in
          EventButton(event: event, onSelect: onSelect)
            .frame(height: 20)  // Fixed height for consistent layout
        }

        // Overflow indicator
        if events.count > maxVisibleEvents {
          Button(action: {
            showOverflowPopover = true
            // Get position for popover
            let mouseLocation = NSEvent.mouseLocation
            if let window = NSApplication.shared.windows.first {
              overflowPopoverPosition = window.convertPoint(fromScreen: mouseLocation)
            }
          }) {
            Text("+\(events.count - maxVisibleEvents) more")
              .font(.caption2.weight(.medium))
              .foregroundColor(.secondary)
              .padding(.horizontal, 8)
              .padding(.vertical, 2)
          }
          .buttonStyle(.plain)
          .frame(height: 20)  // Fixed height for consistent layout
        }

        Spacer(minLength: 0)
      }
      .padding(.horizontal, 4)
      .padding(.bottom, 4)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(
      Rectangle()
        .fill(date.isToday ? CalendarStyle.todayBackground : Color.clear)
    )
    .overlay(
      Rectangle()
        .stroke(CalendarStyle.gridLine, lineWidth: 0.5)
    )
    .popover(isPresented: $showOverflowPopover) {
      OverflowEventsView(
        date: date,
        events: Array(events.dropFirst(maxVisibleEvents)),
        onSelectEvent: onSelect
      )
      .frame(width: 300, height: 400)
    }
  }
}

private struct OverflowEventsView: View {
  let date: Date
  let events: [CalendarEvent]
  let onSelectEvent: (CalendarEvent, CGPoint) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Header
      HStack {
        Text(date, format: .dateTime.month().day())
          .font(.headline.weight(.semibold))
        Spacer()
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(CalendarStyle.panelBackground)

      Divider()

      // Events list
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 8) {
          ForEach(events) { event in
            OverflowEventRow(event: event) {
              let mouseLocation = NSEvent.mouseLocation
              if let window = NSApplication.shared.windows.first {
                let windowPoint = window.convertPoint(fromScreen: mouseLocation)
                onSelectEvent(event, windowPoint)
              }
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
      }
    }
    .background(CalendarStyle.background)
  }
}

private struct OverflowEventRow: View {
  let event: CalendarEvent
  let onSelect: () -> Void
  @State private var isHovering = false

  var body: some View {
    Button(action: onSelect) {
      HStack(spacing: 8) {
        // Time
        Text(event.startDate, format: .dateTime.hour().minute())
          .font(.caption2.weight(.medium))
          .foregroundColor(.secondary)
          .frame(width: 50, alignment: .leading)

        // Color indicator
        Circle()
          .fill(Color(hex: event.colorHex ?? "#5E6AD2"))
          .frame(width: 8, height: 8)

        // Event title
        VStack(alignment: .leading, spacing: 2) {
          Text(event.title)
            .font(.subheadline.weight(.medium))
            .foregroundColor(.primary)
            .lineLimit(2)

          if let location = event.location, !location.isEmpty {
            Text(location)
              .font(.caption2)
              .foregroundColor(.secondary)
              .lineLimit(1)
          }
        }

        Spacer()
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(
        RoundedRectangle(cornerRadius: 6)
          .fill(Color(hex: event.colorHex ?? "#5E6AD2").opacity(isHovering ? 0.1 : 0.05))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 6)
          .stroke(Color(hex: event.colorHex ?? "#5E6AD2").opacity(0.3), lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
  }
}

private struct EventButton: View {
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
      HStack(spacing: 4) {
        Circle()
          .fill(Color(hex: event.colorHex ?? "#5E6AD2"))
          .frame(width: 6, height: 6)

        Text(event.title)
          .font(.caption2.weight(.medium))
          .lineLimit(1)
          .foregroundColor(.primary)

        Spacer(minLength: 0)
      }
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(
        RoundedRectangle(cornerRadius: 3)
          .fill(Color(hex: event.colorHex ?? "#5E6AD2").opacity(isHovering ? 0.2 : 0.1))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 3)
          .stroke(Color(hex: event.colorHex ?? "#5E6AD2").opacity(0.6), lineWidth: 0.5)
      )
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
  }
}

// Color(hex:) extension moved to Extensions/Color+Hex.swift
