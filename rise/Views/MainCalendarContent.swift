import SwiftUI

struct MainCalendarContent: View {
  @ObservedObject var vm: AppViewModel
  @Binding var selectedEvent: CalendarEvent?
  @Binding var isDetailSidebarVisible: Bool

  var body: some View {
    Group {
      // Main calendar view fills the entire available window area
      switch vm.selectedViewMode {
      case .day:
        CalendarDayView(
          date: vm.selectedDate,
          events: vm.events,
          onSelectEvent: { event, point in
            selectedEvent = event
            isDetailSidebarVisible = true
          }
        )
      case .week:
        let startOfWeek =
          Calendar.current.dateInterval(of: .weekOfYear, for: vm.selectedDate)?.start
          ?? vm.selectedDate
        if vm.selectedWeekStyle == .grid {
          CalendarTimeGridWeekView(
            startOfWeek: startOfWeek,
            events: vm.events,
            onSelectEvent: { event, point in
              selectedEvent = event
              isDetailSidebarVisible = true
            }
          )
        } else {
          CalendarWeekView(
            startOfWeek: startOfWeek,
            events: vm.events,
            onSelectEvent: { event, point in
              selectedEvent = event
              isDetailSidebarVisible = true
            }
          )
        }
      case .month:
        CalendarMonthView(
          date: vm.selectedDate,
          events: vm.events,
          onSelectEvent: { event, point in
            selectedEvent = event
            isDetailSidebarVisible = true
          },
          onNavigateMonth: { increment in
            vm.selectedDate =
              Calendar.current.date(byAdding: .month, value: increment, to: vm.selectedDate)
              ?? vm.selectedDate
          }
        )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

struct CalendarToolbar: ToolbarContent {
  @ObservedObject var vm: AppViewModel

  var body: some ToolbarContent {
    ToolbarItemGroup(placement: .navigation) {
      Button(action: { navigateDate(increment: -1) }) { Image(systemName: "chevron.left") }
      Button("Today") { vm.selectedDate = Date() }
      Button(action: { navigateDate(increment: 1) }) { Image(systemName: "chevron.right") }
    }

    ToolbarItem(placement: .principal) {
      switch vm.selectedViewMode {
      case .day:
        Text(dayString(for: vm.selectedDate)).font(.system(size: 14, weight: .semibold))
      case .week:
        Text(weekRangeString(for: vm.selectedDate)).font(.system(size: 14, weight: .semibold))
      case .month:
        Text(monthYearString(for: vm.selectedDate)).font(.system(size: 14, weight: .semibold))
      }
    }

    ToolbarItem(placement: .automatic) {
      Picker("View", selection: $vm.selectedViewMode) {
        ForEach(AppViewModel.ViewMode.allCases, id: \.self) { mode in
          Text(mode.rawValue).tag(mode)
        }
      }
      .pickerStyle(.segmented)
      .fixedSize()
    }

    ToolbarItem(placement: .automatic) {
      if vm.selectedViewMode == .week {
        Picker("Week Style", selection: $vm.selectedWeekStyle) {
          ForEach(AppViewModel.WeekStyle.allCases, id: \.self) { style in
            Text(style.rawValue).tag(style)
          }
        }
        .pickerStyle(.menu)
      }
    }
  }

  private func monthYearString(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = .current
    formatter.locale = .current
    formatter.dateFormat = "LLLL yyyy"
    return formatter.string(from: date)
  }

  private func dayString(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = .current
    formatter.locale = .current
    formatter.dateStyle = .full
    formatter.timeStyle = .none
    return formatter.string(from: date)
  }

  private func weekRangeString(for date: Date) -> String {
    let calendar = Calendar.current
    let interval =
      calendar.dateInterval(of: .weekOfYear, for: date)
      ?? DateInterval(start: date, end: date)
    let endExclusive = interval.end.addingTimeInterval(-1)

    let formatter = DateIntervalFormatter()
    formatter.calendar = .current
    formatter.locale = .current
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: interval.start, to: endExclusive)
  }

  private func navigateDate(increment: Int) {
    let actualIncrement: Int
    switch vm.selectedViewMode {
    case .day:
      actualIncrement = increment
    case .week:
      actualIncrement = increment * 7
    case .month:
      actualIncrement = increment
    }

    if vm.selectedViewMode == .month {
      vm.selectedDate =
        Calendar.current.date(byAdding: .month, value: actualIncrement, to: vm.selectedDate)
        ?? vm.selectedDate
    } else {
      vm.selectedDate =
        Calendar.current.date(byAdding: .day, value: actualIncrement, to: vm.selectedDate)
        ?? vm.selectedDate
    }
  }
}

// MARK: - Extensions

extension CalendarEvent {
  var isAllDay: Bool {
    let calendar = Calendar.current
    return calendar.isDate(startDate, inSameDayAs: endDate)
      && calendar.component(.hour, from: startDate) == 0
      && calendar.component(.minute, from: startDate) == 0
  }

  var duration: TimeInterval {
    return endDate.timeIntervalSince(startDate)
  }

  var formattedTime: String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
  }

  var formattedDate: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: startDate)
  }
}
