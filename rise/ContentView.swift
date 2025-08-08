//
//  ContentView.swift
//  rise
//
//  Created by Piyush Bhutoria on 08/08/25.
//

import SwiftUI

struct ContentView: View {
  @ObserveInjection var inject
  @StateObject private var vm = AppViewModel()
  @State private var selectedEvent: CalendarEvent?
  @State private var showDetails = false
  @State private var eventDetailPosition: CGPoint = .zero
  @EnvironmentObject private var preferencesManager: PreferencesManager

  private var dateDisplayText: String {
    switch vm.selectedViewMode {
    case .day:
      return vm.selectedDate.formatted(date: .complete, time: .omitted)
    case .week:
      let startOfWeek =
        Calendar.current.date(
          from: Calendar.current.dateComponents(
            [.yearForWeekOfYear, .weekOfYear], from: vm.selectedDate)) ?? vm.selectedDate
      let endOfWeek =
        Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) ?? vm.selectedDate
      return
        "\(startOfWeek.formatted(date: .abbreviated, time: .omitted)) - \(endOfWeek.formatted(date: .abbreviated, time: .omitted))"
    case .month:
      return vm.selectedDate.formatted(.dateTime.month(.wide).year())
    }
  }

  var body: some View {
    NavigationSplitView {
      VStack(alignment: .leading, spacing: 12) {
        // Header with title only (settings moved to menu)
        HStack {
          Text("Calendars")
            .font(.headline)
            .foregroundColor(.primary)

          Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)

        Divider()

        // Calendars list with color-coded checkboxes
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 8) {
            ForEach(vm.accounts) { account in
              if let calendars = vm.calendarsByAccount[account.email], !calendars.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                  // Account header
                  HStack {
                    Circle()
                      .fill(Color(hex: account.colorHex))
                      .frame(width: 8, height: 8)
                    Text(account.email)
                      .font(.caption)
                      .foregroundColor(.secondary)
                    Spacer()
                  }
                  .padding(.horizontal, 12)
                  .padding(.top, 8)

                  // Calendar checkboxes
                  ForEach(calendars) { calendar in
                    CalendarCheckboxRow(
                      calendar: calendar,
                      accountEmail: account.email,
                      vm: vm
                    )
                  }
                }
              }
            }
          }
          .padding(.bottom, 12)
        }

        Spacer()

        // Add account button at bottom
        VStack(spacing: 8) {
          Divider()

          Button {
            if let window = NSApplication.shared.windows.first {
              vm.addGoogleAccount(presentationAnchor: window)
            }
          } label: {
            Label("Add Calendar Account", systemImage: "person.crop.circle.badge.plus")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
          .padding(.horizontal, 12)
          .padding(.bottom, 8)
        }
      }
      .navigationSplitViewColumnWidth(min: 200, ideal: 240)
    } detail: {
      ZStack {
        VStack(spacing: 0) {
          // Main content area with proper scrolling
          Group {
            switch vm.selectedViewMode {
            case .day:
              CalendarDayView(date: vm.selectedDate, events: vm.events) { ev, position in
                selectedEvent = ev
                eventDetailPosition = position
                showDetails = true
              }
              .responsiveLayout()
            case .month:
              CalendarMonthView(
                date: vm.selectedDate, events: vm.events,
                onSelectEvent: { ev, position in
                  selectedEvent = ev
                  eventDetailPosition = position
                  showDetails = true
                },
                onNavigateMonth: nil  // Navigation handled by main toolbar
              )
              .responsiveLayout()
            case .week:
              let startOfWeek =
                Calendar.current.date(
                  from: Calendar.current.dateComponents(
                    [.yearForWeekOfYear, .weekOfYear], from: vm.selectedDate)) ?? vm.selectedDate
              if vm.selectedWeekStyle == .list {
                CalendarWeekView(startOfWeek: startOfWeek, events: vm.events) { ev, position in
                  selectedEvent = ev
                  eventDetailPosition = position
                  showDetails = true
                }
                .responsiveLayout()
              } else {
                CalendarTimeGridWeekView(startOfWeek: startOfWeek, events: vm.events) {
                  ev, position in
                  selectedEvent = ev
                  eventDetailPosition = position
                  showDetails = true
                }
                .responsiveLayout()
              }
            }
          }
        }

        // Floating event detail overlay
        if showDetails, let event = selectedEvent {
          FloatingEventDetailView(
            event: event,
            position: eventDetailPosition,
            onDismiss: {
              showDetails = false
              selectedEvent = nil
            }
          )
        }
      }
      .toolbar {
        ToolbarItemGroup(placement: .navigation) {
          // Date display - only show for day and week views, not month view
          if vm.selectedViewMode != .month {
            HStack(spacing: 8) {
              Text(dateDisplayText)
                .font(.title2.weight(.medium))
                .frame(minWidth: 160, alignment: .leading)
            }
          }
        }

        ToolbarItemGroup(placement: .primaryAction) {
          // View mode picker - Mac Calendar style
          Picker("View", selection: $vm.selectedViewMode) {
            ForEach(AppViewModel.ViewMode.allCases, id: \.self) { m in
              Text(m.rawValue).tag(m)
            }
          }
          .pickerStyle(.segmented)
          .frame(width: 180)
          .controlSize(.large)

          // Week style toggle - only show when in week view
          if vm.selectedViewMode == .week {
            Picker("Week Style", selection: $vm.selectedWeekStyle) {
              ForEach(AppViewModel.WeekStyle.allCases, id: \.self) { style in
                Text(style.rawValue).tag(style)
              }
            }
            .pickerStyle(.segmented)
            .frame(width: 120)
            .controlSize(.small)
          }

          // Navigation buttons - Mac Calendar style
          Button(action: {
            let increment: Int
            switch vm.selectedViewMode {
            case .day:
              increment = -1
            case .week:
              increment = -7
            case .month:
              increment = -1  // Navigate by month
            }
            if vm.selectedViewMode == .month {
              vm.selectedDate =
                Calendar.current.date(byAdding: .month, value: increment, to: vm.selectedDate)
                ?? vm.selectedDate
            } else {
              vm.selectedDate =
                Calendar.current.date(byAdding: .day, value: increment, to: vm.selectedDate)
                ?? vm.selectedDate
            }
          }) {
            Image(systemName: "chevron.left")
          }
          .buttonStyle(.borderless)

          Button(action: {
            let increment: Int
            switch vm.selectedViewMode {
            case .day:
              increment = 1
            case .week:
              increment = 7
            case .month:
              increment = 1  // Navigate by month
            }
            if vm.selectedViewMode == .month {
              vm.selectedDate =
                Calendar.current.date(byAdding: .month, value: increment, to: vm.selectedDate)
                ?? vm.selectedDate
            } else {
              vm.selectedDate =
                Calendar.current.date(byAdding: .day, value: increment, to: vm.selectedDate)
                ?? vm.selectedDate
            }
          }) {
            Image(systemName: "chevron.right")
          }
          .buttonStyle(.borderless)

          // Today button
          Button("Today") {
            vm.selectedDate = Date()
          }
          .buttonStyle(.borderless)
        }
      }
    }
    .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
      Button("OK") { vm.errorMessage = nil }
    } message: {
      Text(vm.errorMessage ?? "")
    }
    .enableInjection()
  }
}

struct CalendarRow: View {
  let calendar: GoogleCalendar
  let accountEmail: String
  let vm: AppViewModel
  @State private var isHovering = false
  @State private var showColorPicker = false

  var body: some View {
    HStack(spacing: 8) {
      // Color indicator
      Button(action: { showColorPicker.toggle() }) {
        Circle()
          .fill(Color(hex: calendar.displayColor))
          .frame(width: 12, height: 12)
          .overlay(
            Circle()
              .stroke(Color.primary.opacity(0.2), lineWidth: 1)
          )
      }
      .buttonStyle(.plain)
      .popover(isPresented: $showColorPicker) {
        ColorPickerView(
          selectedColor: calendar.displayColor,
          onColorSelected: { color in
            vm.updateCalendarColor(email: accountEmail, calendarId: calendar.id, color: color)
            showColorPicker = false
          }
        )
        .frame(width: 200, height: 150)
      }

      // Calendar name
      Text(calendar.summary)
        .font(.subheadline)
        .lineLimit(1)

      Spacer()

      // Visibility toggle
      Toggle(
        "",
        isOn: Binding(
          get: { calendar.isVisible },
          set: { newVal in
            vm.toggleCalendarVisibility(
              email: accountEmail, calendarId: calendar.id, isVisible: newVal)
          }
        )
      )
      .toggleStyle(.switch)
      .labelsHidden()
      .scaleEffect(0.8)
    }
    .padding(.vertical, 2)
    .onHover { isHovering = $0 }
  }
}

struct ColorPickerView: View {
  let selectedColor: String
  let onColorSelected: (String) -> Void

  private let colors = [
    "#4285F4", "#DB4437", "#F4B400", "#0F9D58", "#AB47BC", "#00ACC1",
    "#FF6D01", "#46BDC6", "#7B1FA2", "#388E3C", "#D32F2F", "#1976D2",
    "#FF5722", "#795548", "#607D8B", "#9E9E9E", "#FF9800", "#4CAF50",
  ]

  var body: some View {
    VStack(spacing: 12) {
      Text("Choose Color")
        .font(.headline)

      LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
        ForEach(colors, id: \.self) { color in
          Button(action: { onColorSelected(color) }) {
            Circle()
              .fill(Color(hex: color))
              .frame(width: 24, height: 24)
              .overlay(
                Circle()
                  .stroke(Color.primary, lineWidth: color == selectedColor ? 2 : 0)
              )
          }
          .buttonStyle(.plain)
        }
      }
    }
    .padding()
  }
}

struct FloatingEventDetailView: View {
  let event: CalendarEvent
  let position: CGPoint
  let onDismiss: () -> Void
  @FocusState private var isFocused: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Header with title and calendar indicator
      HStack(alignment: .top, spacing: 8) {
        Image(systemName: "calendar")
          .foregroundColor(.secondary)
          .font(.caption)
        Text(event.title)
          .font(.headline)
          .fontWeight(.medium)
        Spacer()
      }

      // Date and time
      VStack(alignment: .leading, spacing: 4) {
        Text(
          "\(event.startDate.formatted(date: .abbreviated, time: .shortened)) - \(event.endDate.formatted(date: .abbreviated, time: .shortened))"
        )
        .font(.subheadline)
        .foregroundColor(.secondary)
      }

      // Location (if available)
      if let location = event.location, !location.isEmpty {
        VStack(alignment: .leading, spacing: 4) {
          Label("Location", systemImage: "location")
            .font(.caption)
            .foregroundColor(.secondary)
          Text(location)
            .font(.subheadline)
        }
      }

      // Meeting URL button
      if let url = event.meetingURL {
        Button(action: {
          NSWorkspace.shared.open(url)
          onDismiss()
        }) {
          Label("Join Meeting", systemImage: "video.fill")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
      }

      // Description (if available)
      if let description = event.description, !description.isEmpty {
        VStack(alignment: .leading, spacing: 4) {
          Label("Notes", systemImage: "note.text")
            .font(.caption)
            .foregroundColor(.secondary)
          ScrollView {
            Text(description)
              .font(.subheadline)
              .textSelection(.enabled)
          }
          .frame(maxHeight: 120)
        }
      }

      Spacer(minLength: 0)
    }
    .padding(20)
    .frame(width: 320, height: 280)
    .background(CalendarStyle.panelBackground)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    .focused($isFocused)
    .onAppear {
      isFocused = true
    }
    .onKeyPress(.escape) {
      onDismiss()
      return .handled
    }
    .position(calculateOptimalPosition())
  }

  private func calculateOptimalPosition() -> CGPoint {
    let detailWidth: CGFloat = 320
    let detailHeight: CGFloat = 280
    let padding: CGFloat = 20

    // Get window bounds
    guard let window = NSApplication.shared.windows.first else {
      return CGPoint(x: position.x + 160, y: position.y + 140)
    }

    let windowFrame = window.frame
    let windowWidth = windowFrame.width
    let windowHeight = windowFrame.height

    // Calculate initial position (to the right of the event)
    var x = position.x + 20
    var y = position.y

    // Adjust horizontal position if it would overflow the right edge
    if x + detailWidth / 2 > windowWidth - padding {
      // Position to the left of the event instead
      x = position.x - detailWidth / 2 - 20
    }

    // Ensure minimum left margin
    if x - detailWidth / 2 < padding {
      x = detailWidth / 2 + padding
    }

    // Adjust vertical position if it would overflow the bottom edge
    if y + detailHeight / 2 > windowHeight - padding {
      y = windowHeight - detailHeight / 2 - padding
    }

    // Ensure minimum top margin
    if y - detailHeight / 2 < padding {
      y = detailHeight / 2 + padding
    }

    return CGPoint(x: x, y: y)
  }
}

struct AccountRow: View {
  let account: GoogleAccount
  let vm: AppViewModel
  @State private var isHovering = false

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .center, spacing: 8) {
        Circle().fill(Color(hex: account.colorHex)).frame(width: 8, height: 8)
        Text(account.email)
          .font(.subheadline)
        Spacer()
        Button(role: .destructive) {
          vm.removeAccount(email: account.email)
        } label: {
          Image(systemName: "trash")
            .foregroundColor(.secondary)
        }
        .buttonStyle(.borderless)
        .opacity(isHovering ? 1 : 0.6)
      }

      // Auto-join toggle with improved UI
      HStack(spacing: 8) {
        Image(systemName: "video.fill")
          .foregroundColor(.secondary)
          .font(.caption)

        VStack(alignment: .leading, spacing: 2) {
          Text("Auto-join meetings")
            .font(.caption)
            .foregroundColor(.primary)
          Text("Automatically join video calls")
            .font(.caption2)
            .foregroundColor(.secondary)
        }

        Spacer()

        Toggle(
          "",
          isOn: Binding(
            get: { account.autoJoinEnabled },
            set: { newVal in
              vm.updateAutoJoin(email: account.email, enabled: newVal)
            }
          )
        )
        .toggleStyle(.switch)
        .labelsHidden()
        .scaleEffect(0.8)
      }
      .padding(.leading, 16)
    }
    .padding(.vertical, 4)
    .onHover { isHovering = $0 }
  }
}

struct CalendarCheckboxRow: View {
  let calendar: GoogleCalendar
  let accountEmail: String
  let vm: AppViewModel
  @State private var isHovering = false
  @State private var showColorPicker = false

  var body: some View {
    HStack(spacing: 8) {
      // Color-coded checkbox
      Button(action: {
        vm.toggleCalendarVisibility(
          email: accountEmail, calendarId: calendar.id, isVisible: !calendar.isVisible)
      }) {
        HStack(spacing: 6) {
          Image(systemName: calendar.isVisible ? "checkmark.square.fill" : "square")
            .foregroundColor(Color(hex: calendar.displayColor))
            .font(.system(size: 12, weight: .medium))

          Text(calendar.summary)
            .font(.subheadline)
            .foregroundColor(.primary)

          Spacer(minLength: 0)
        }
      }
      .buttonStyle(.plain)

      // Color picker button
      Button(action: { showColorPicker.toggle() }) {
        Circle()
          .fill(Color(hex: calendar.displayColor))
          .frame(width: 10, height: 10)
          .overlay(
            Circle()
              .stroke(Color.primary.opacity(0.2), lineWidth: 1)
          )
      }
      .buttonStyle(.plain)
      .opacity(isHovering ? 1 : 0.6)
      .popover(isPresented: $showColorPicker) {
        ColorPickerView(
          selectedColor: calendar.displayColor,
          onColorSelected: { color in
            vm.updateCalendarColor(email: accountEmail, calendarId: calendar.id, color: color)
            showColorPicker = false
          }
        )
        .frame(width: 200, height: 150)
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 4)
    .background(
      RoundedRectangle(cornerRadius: 4)
        .fill(isHovering ? Color(NSColor.controlBackgroundColor) : Color.clear)
    )
    .onHover { isHovering = $0 }
  }
}
