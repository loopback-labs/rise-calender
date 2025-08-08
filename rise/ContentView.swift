import SwiftUI

struct ContentView: View {
  @ObserveInjection var inject
  @StateObject var vm: AppViewModel
  @State private var selectedEvent: CalendarEvent?
  @State private var isDetailSidebarVisible = false
  @State private var popoverAnchorPoint: CGPoint?

  var body: some View {
    NavigationSplitView(
      sidebar: {
        CalendarSidebar(vm: vm)
      },
      content: {
        MainCalendarContent(
          vm: vm,
          selectedEvent: $selectedEvent,
          isDetailSidebarVisible: $isDetailSidebarVisible,
          popoverAnchorPoint: $popoverAnchorPoint
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
          AnchoredPopover(
            isPresented: $isDetailSidebarVisible,
            anchorPointInWindow: popoverAnchorPoint,
            onClose: {
              selectedEvent = nil
              isDetailSidebarVisible = false
            }
          ) {
            if let event = selectedEvent {
              EventDetailPopover(
                event: event,
                onDismiss: {
                  selectedEvent = nil
                  isDetailSidebarVisible = false
                }
              )
            } else {
              EmptyView()
            }
          }
        )
      },
      detail: { EmptyView() }
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

  // navigateDate removed; navigation logic centralized in `CalendarToolbar`
}
