import SwiftUI

struct CalendarMonthView: View {
  @ObserveInjection var inject
  let date: Date
  let events: [CalendarEvent]
  let onSelectEvent: (CalendarEvent) -> Void

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
      VStack(spacing: 8) {
        Grid(alignment: .topLeading, horizontalSpacing: 8, verticalSpacing: 8) {
          GridRow {
            ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { d in
              Text(d).font(.caption).foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
            }
          }
          ForEach(0..<rows, id: \.self) { row in
            GridRow {
              ForEach(0..<7, id: \.self) { col in
                let cellIndex = row * 7 + col
                if cellIndex < leadingBlanks || cellIndex >= totalCells {
                  Rectangle().fill(Color.clear).frame(minHeight: 92)
                } else {
                  let dayOffset = cellIndex - leadingBlanks
                  let dayDate = cal.date(byAdding: .day, value: dayOffset, to: md.firstDay)!
                  DayCell(date: dayDate, events: eventsFor(dayDate)) { ev in onSelectEvent(ev) }
                }
              }
            }
          }
        }
        .frame(minWidth: 700, minHeight: 480)
      }
      .padding(8)
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
  let onSelect: (CalendarEvent) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 6) {
        Text(date, format: .dateTime.weekday(.abbreviated))
          .font(.caption2)
          .foregroundColor(.secondary)
        TodayBadge(date: date)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      LazyVStack(alignment: .leading, spacing: 2) {
        ForEach(events.prefix(3)) { ev in
          Button(action: { onSelect(ev) }) {
            HStack(spacing: 6) {
              Circle().fill(Color(hex: ev.colorHex ?? "#5E6AD2")).frame(width: 6, height: 6)
              Text(ev.title).lineLimit(1).font(.caption)
            }
          }
          .buttonStyle(.plain)
        }
        if events.count > 3 {
          Text("+\(events.count - 3) more").font(.caption2).foregroundColor(.secondary)
        }
      }
      Spacer(minLength: 0)
    }
    .padding(8)
    .frame(minHeight: 92, maxHeight: .infinity, alignment: .topLeading)
    .background(
      RoundedRectangle(cornerRadius: CalendarStyle.monthCellCornerRadius)
        .fill(CalendarStyle.panelBackground)
    )
  }
}

// Color(hex:) extension moved to Extensions/Color+Hex.swift
