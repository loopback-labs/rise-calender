import SwiftUI

struct CalendarDayView: View {
  @ObserveInjection var inject
  let date: Date
  let events: [CalendarEvent]
  let onSelectEvent: (CalendarEvent, CGPoint) -> Void

  private let hours: [Int] = Array(0...23)

  var body: some View {
    ScrollView([.vertical, .horizontal], showsIndicators: false) {
      VStack(spacing: 0) {
        // All-day events section
        AllDayEventsDayRow(date: date, events: events, onSelectEvent: onSelectEvent)
          .frame(height: 72) // Increased height for better visibility
          .padding(.horizontal, 16) // Increased padding
          .padding(.vertical, 12) // Increased padding

        Divider()
          .padding(.horizontal, 16) // Added horizontal padding

        // Time grid section
        HStack(alignment: .top, spacing: 20) { // Increased spacing
          HourGutter(hours: hours)

          // Single day column
          VStack(spacing: 8) { // Increased spacing
            DayHeader(date: date)
            DayColumn(day: date, events: eventsFor(date), onSelectEvent: onSelectEvent)
              .overlay(alignment: .topLeading) {
                if date.isToday { NowIndicator(startOfDay: date) }
              }
          }
          .frame(minWidth: CalendarStyle.dayColumnMinWidth)
        }
        .padding(16) // Increased padding
        .frame(
          minWidth: CalendarStyle.dayColumnMinWidth + 60 + 16 * 2, // Updated width calculation
          minHeight: 24 * CalendarStyle.hourRowHeight)
      }
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

struct AllDayEventsDayRow: View {
  let date: Date
  let events: [CalendarEvent]
  let onSelectEvent: (CalendarEvent, CGPoint) -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 20) { // Increased spacing
      // All-day label
      Text("all-day")
        .font(.caption2.weight(.medium))
        .foregroundColor(.secondary)
        .frame(width: 60, alignment: .trailing) // Increased width
        .padding(.top, 6) // Increased padding

      // Single day column for all-day events
      AllDayColumn(day: date, events: allDayEventsFor(date), onSelectEvent: onSelectEvent)
        .frame(minWidth: CalendarStyle.dayColumnMinWidth)
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
