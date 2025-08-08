import SwiftUI

struct ContentView: View {
  @ObserveInjection var inject
  @StateObject var vm: AppViewModel
  @State private var selectedEvent: CalendarEvent?
  @State private var isDetailSidebarVisible = false

  var body: some View {
    NavigationSplitView(
      sidebar: {
        CalendarSidebar(vm: vm)
      },
      content: {
        MainCalendarContent(
          vm: vm,
          selectedEvent: $selectedEvent,
          isDetailSidebarVisible: $isDetailSidebarVisible
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      },
      detail: {
        if isDetailSidebarVisible {
          EventDetailSidebar(
            event: selectedEvent,
            onDismiss: {
              selectedEvent = nil
              isDetailSidebarVisible = false
            }
          )
          .frame(minWidth: 280)
        }
      }
    )
    .background(CalendarStyle.background)
    .toolbar { CalendarToolbar(vm: vm) }
    .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
      Button("OK") { vm.errorMessage = nil }
    } message: {
      Text(vm.errorMessage ?? "")
    }
    .enableInjection()
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
