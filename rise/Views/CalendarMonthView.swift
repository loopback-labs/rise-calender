import SwiftUI

struct CalendarMonthView: View {
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
    let fixedCells = 42  // Always render 6 full weeks for consistent month grid

    VStack(spacing: 0) {
      MonthWeekdaysHeaderRow()
        .padding(.horizontal, CalendarStyle.spacingXLarge)

      LazyVGrid(
        columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
        spacing: 0
      ) {
        ForEach(0..<fixedCells, id: \.self) { cellIndex in
          let dayOffset = cellIndex - leadingBlanks
          let dayDate = cal.date(byAdding: .day, value: dayOffset, to: md.firstDay)!
          let isCurrentMonth = cal.isDate(dayDate, equalTo: md.firstDay, toGranularity: .month)

          DayCell(
            date: dayDate,
            events: isCurrentMonth ? eventsFor(dayDate) : [],
            isCurrentMonth: isCurrentMonth,
            onSelect: { ev, position in onSelectEvent(ev, position) }
          )
          .frame(height: CalendarStyle.monthCellHeight)
        }
      }
      .padding(.horizontal, CalendarStyle.spacingXLarge)
      .background(CalendarStyle.background)
    }
    .background(CalendarStyle.background)
  }

  private func eventsFor(_ day: Date) -> [CalendarEvent] {
    let cal = Calendar.current
    return events.filter { cal.isDate($0.startDate, inSameDayAs: day) }
  }
}

private struct MonthWeekdaysHeaderRow: View {
  var body: some View {
    HStack(spacing: 0) {
      ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { day in
        Text(day)
          .font(CalendarStyle.fontCaption.weight(.medium))
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity)
          .frame(height: CalendarStyle.dayHeaderHeight)
      }
    }
  }

}

private struct DayCell: View {
  let date: Date
  let events: [CalendarEvent]
  let isCurrentMonth: Bool
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
          .font(CalendarStyle.fontCaption.weight(.medium))
          .foregroundColor(date.isToday ? .white : (isCurrentMonth ? .primary : .secondary))
          .padding(.horizontal, 4)
          .padding(.vertical, 2)
          .background(
            Circle()
              .fill(date.isToday ? Color.accentColor : Color.clear)
          )

        Spacer()
      }
      .frame(height: 24)
      .padding(.horizontal, 4)
      .padding(.top, 2)

      // Events section
      VStack(alignment: .leading, spacing: 1) {
        ForEach(Array(events.prefix(maxVisibleEvents).enumerated()), id: \.element.id) {
          index, event in
          EventButton(event: event, onSelect: onSelect)
            .frame(height: 16)  // Fixed height for consistent layout
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
              .font(CalendarStyle.fontCaption.weight(.medium))
              .foregroundColor(.secondary)
              .padding(.horizontal, 4)
              .padding(.vertical, 1)
          }
          .buttonStyle(.plain)
          .frame(height: 16)  // Fixed height for consistent layout
        }

        Spacer(minLength: 0)
      }
      .padding(.horizontal, 2)
      .padding(.bottom, 2)
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
      // Size to content to eliminate extra empty space while capping max height
      .frame(width: 300)
      .frame(maxHeight: 400)
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
          .font(CalendarStyle.fontHeadline.weight(.semibold))
        Spacer()
      }
      .padding(.horizontal, CalendarStyle.spacingXLarge)
      .padding(.vertical, CalendarStyle.spacingLarge)
      .background(CalendarStyle.panelBackground)

      Divider()

      // Events list
      ScrollView {
        LazyVStack(alignment: .leading, spacing: CalendarStyle.spacingMedium) {
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
        .padding(.horizontal, CalendarStyle.spacingXLarge)
        .padding(.vertical, CalendarStyle.spacingLarge)
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
      HStack(spacing: CalendarStyle.spacingMedium) {
        // Time
        Text(event.startDate, format: .dateTime.hour().minute())
          .font(CalendarStyle.fontCaption)
          .foregroundColor(.secondary)
          .frame(width: 50, alignment: .leading)

        // Color indicator
        Circle()
          .fill(Color(hex: event.colorHex ?? "#5E6AD2"))
          .frame(width: 8, height: 8)

        // Event details
        VStack(alignment: .leading, spacing: CalendarStyle.spacingSmall) {
          Text(event.title)
            .font(CalendarStyle.fontBody)
            .foregroundColor(.primary)
            .lineLimit(2)

          if let location = event.location, !location.isEmpty {
            Text(location)
              .font(CalendarStyle.fontCaption)
              .foregroundColor(.secondary)
              .lineLimit(1)
          }
        }

        Spacer()
      }
      .padding(.horizontal, CalendarStyle.spacingMedium)
      .padding(.vertical, CalendarStyle.spacingSmall)
      .background(
        RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
          .fill(isHovering ? CalendarStyle.hoverBackground : Color.clear)
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
      let mouseLocation = NSEvent.mouseLocation
      if let window = NSApplication.shared.windows.first {
        let windowPoint = window.convertPoint(fromScreen: mouseLocation)
        onSelect(event, windowPoint)
      }
    }) {
      HStack(spacing: 2) {
        // Color indicator
        Circle()
          .fill(Color(hex: event.colorHex ?? "#5E6AD2"))
          .frame(width: 6, height: 6)

        // Event title
        Text(event.title)
          .font(CalendarStyle.fontCaption)
          .foregroundColor(.primary)
          .lineLimit(1)

        Spacer(minLength: 0)
      }
      .padding(.horizontal, 2)
      .padding(.vertical, 1)
      .background(
        RoundedRectangle(cornerRadius: 2)
          .fill(isHovering ? CalendarStyle.hoverBackground : Color.clear)
      )
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
  }
}

#if DEBUG
  #Preview {
    CalendarMonthView(date: Date(), events: [], onSelectEvent: { _, _ in })
  }
#endif
