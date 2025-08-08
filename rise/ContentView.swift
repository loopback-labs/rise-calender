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

  var body: some View {
    NavigationSplitView {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Button {
            if let window = NSApplication.shared.windows.first {
              vm.addGoogleAccount(presentationAnchor: window)
            }
          } label: {
            Label("Add Google Account", systemImage: "person.crop.circle.badge.plus")
          }
        }
        .padding(.bottom, 8)

        List {
          Section("Connected Accounts") {
            ForEach(vm.accounts) { account in
              HStack(alignment: .center, spacing: 8) {
                Circle().fill(Color(hex: account.colorHex)).frame(width: 8, height: 8)
                Text(account.email)
                Spacer()
                Toggle(
                  "Auto-join",
                  isOn: Binding(
                    get: { account.autoJoinEnabled },
                    set: { newVal in
                      vm.updateAutoJoin(email: account.email, enabled: newVal)
                    }
                  )
                )
                .toggleStyle(.switch)
                .labelsHidden()
                Button(role: .destructive) {
                  vm.removeAccount(email: account.email)
                } label: {
                  Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
              }
            }
          }
        }
        Spacer()
      }
      .padding(8)
      .navigationSplitViewColumnWidth(min: 240, ideal: 260)
    } detail: {
      VStack(spacing: 0) {
        // Main content area with proper scrolling
        if vm.selectedViewMode == .month {
          CalendarMonthView(date: vm.selectedDate, events: vm.events) { ev in
            selectedEvent = ev
            showDetails = true
          }
          .responsiveLayout()
        } else {
          let startOfWeek =
            Calendar.current.date(
              from: Calendar.current.dateComponents(
                [.yearForWeekOfYear, .weekOfYear], from: vm.selectedDate)) ?? vm.selectedDate
          Group {
            if vm.selectedWeekStyle == .list {
              CalendarWeekView(startOfWeek: startOfWeek, events: vm.events) { ev in
                selectedEvent = ev
                showDetails = true
              }
              .responsiveLayout()
            } else {
              CalendarTimeGridWeekView(startOfWeek: startOfWeek, events: vm.events) { ev in
                selectedEvent = ev
                showDetails = true
              }
              .responsiveLayout()
            }
          }
        }
      }
      .toolbar {
        ToolbarItemGroup(placement: .navigation) {
          // Date display - matching Mac Calendar style
          HStack(spacing: 8) {
            Text(vm.selectedDate, format: .dateTime.month(.wide).year())
              .font(.title2.weight(.medium))
              .frame(minWidth: 160, alignment: .leading)
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
          .frame(width: 140)

          // Navigation buttons - Mac Calendar style
          Button(action: {
            vm.selectedDate =
              Calendar.current.date(
                byAdding: .day, value: vm.selectedViewMode == .month ? -30 : -7, to: vm.selectedDate
              ) ?? vm.selectedDate
          }) {
            Image(systemName: "chevron.left")
          }
          .buttonStyle(.borderless)

          Button(action: { vm.selectedDate = Date() }) {
            Text("Today")
          }
          .buttonStyle(.borderless)

          Button(action: {
            vm.selectedDate =
              Calendar.current.date(
                byAdding: .day, value: vm.selectedViewMode == .month ? 30 : 7, to: vm.selectedDate)
              ?? vm.selectedDate
          }) {
            Image(systemName: "chevron.right")
          }
          .buttonStyle(.borderless)

          // Week style picker (only for week view)
          if vm.selectedViewMode == .week {
            Picker("Style", selection: $vm.selectedWeekStyle) {
              ForEach(AppViewModel.WeekStyle.allCases, id: \.self) { s in
                Text(s.rawValue).tag(s)
              }
            }
            .pickerStyle(.segmented)
            .frame(width: 140)
          }

          Spacer()

          // Refresh button
          Button(action: { Task { await vm.refreshAllAccounts() } }) {
            Label("Refresh", systemImage: "arrow.clockwise")
          }
          .buttonStyle(.borderless)
        }
      }
      .popover(isPresented: $showDetails, arrowEdge: .top) {
        if let ev = selectedEvent {
          EventDetailView(event: ev)
        }
      }
      .onChange(of: showDetails) { _, newValue in
        if !newValue {
          selectedEvent = nil
        }
      }
    }
    .overlay(alignment: .bottomTrailing) {
      if vm.isBusy {
        ProgressView().padding().background(.ultraThinMaterial).clipShape(
          RoundedRectangle(cornerRadius: 8))
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
