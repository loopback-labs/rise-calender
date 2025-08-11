import SwiftUI

struct CalendarDayView: View {
  let date: Date
  let events: [CalendarEvent]
  let onSelectEvent: (CalendarEvent, CGPoint) -> Void

  private let hours: [Int] = Array(0...23)

  var body: some View {
    ScrollViewReader { proxy in
      // Day view only needs vertical scrolling; using vertical-only ensures the content
      // expands to the full window width for better legibility
      ScrollView(.vertical, showsIndicators: false) {
        VStack(spacing: 0) {
          // All-day events section
          AllDayEventsDayRow(date: date, events: allDayEvents, onSelectEvent: onSelectEvent)
            .frame(height: 72)
            .padding(.horizontal, CalendarStyle.spacingXLarge)
            .padding(.vertical, CalendarStyle.spacingLarge)

          Divider()
            .padding(.horizontal, CalendarStyle.spacingXLarge)

          // Time grid section
          HStack(alignment: .top, spacing: 20) {
            GridHourGutter(hours: hours)

            // Single day column
            VStack(spacing: CalendarStyle.spacingMedium) {
              GridDayHeader(date: date)
              GridDayColumn(day: date, events: timedEvents, onSelectEvent: onSelectEvent)
                .overlay(alignment: .topLeading) {
                  if date.isToday { NowIndicator(startOfDay: date) }
                }
            }
            .frame(minWidth: 360, maxWidth: .infinity)
            .layoutPriority(1)
          }
          .padding(CalendarStyle.spacingXLarge)
          .frame(maxWidth: .infinity, alignment: .leading)

        }
        .frame(maxWidth: .infinity)

        .onAppear {
          // Scroll to current time if viewing today
          if date.isToday {
            scrollToCurrentTime(proxy: proxy)
          }
        }
        .onChange(of: date) { newDate in
          // Scroll to current time when switching to today
          if newDate.isToday {
            scrollToCurrentTime(proxy: proxy)
          }
        }
      }
      .background(CalendarStyle.background)
      .scrollIndicators(.hidden)
    }
  }

  private func scrollToCurrentTime(proxy: ScrollViewProxy) {
    let now = Date()
    let cal = Calendar.current
    let currentHour = cal.component(.hour, from: now)

    // Scroll to current hour with some offset
    let targetHour = max(0, currentHour - 1)  // Show 1 hour before current time
    withAnimation(.easeInOut(duration: 0.5)) {
      proxy.scrollTo("hour-\(targetHour)", anchor: .top)
    }
  }

  // Filter events for the selected day only
  private var allDayEvents: [CalendarEvent] {
    let cal = Calendar.current
    return events.filter { event in
      // Check if event is on the selected day
      cal.isDate(event.startDate, inSameDayAs: date) && event.isAllDay
    }
  }

  private var timedEvents: [CalendarEvent] {
    let cal = Calendar.current
    return events.filter { event in
      // Check if event intersects with the selected day
      // Event starts on the selected day OR event ends on the selected day OR event spans the selected day
      let eventStartsOnDay = cal.isDate(event.startDate, inSameDayAs: date)
      let eventEndsOnDay = cal.isDate(event.endDate, inSameDayAs: date)
      let eventSpansDay = event.startDate < startOfDay && event.endDate > endOfDay

      return (eventStartsOnDay || eventEndsOnDay || eventSpansDay) && !event.isAllDay
    }
  }

  // Helper computed properties for day boundaries
  private var startOfDay: Date {
    let cal = Calendar.current
    return cal.startOfDay(for: date)
  }

  private var endOfDay: Date {
    let cal = Calendar.current
    return cal.date(byAdding: .day, value: 1, to: startOfDay) ?? date
  }

}

struct AllDayEventsDayRow: View {
  let date: Date
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

      // All-day events
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
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

}
