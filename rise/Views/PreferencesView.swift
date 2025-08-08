import SwiftUI

struct PreferencesView: View {
  @ObserveInjection var inject
  @StateObject private var vm = AppViewModel()
  @Environment(\.dismiss) private var dismiss
  @State private var selectedTab = "Accounts"

  private let tabs = [
    ("Accounts", "person.crop.circle"),
    ("General", "gear"),
    ("Advanced", "slider.horizontal.3"),
  ]

  var body: some View {
    NavigationSplitView {
      List(tabs, id: \.0, selection: $selectedTab) { tab in
        Label(tab.0, systemImage: tab.1)
          .tag(tab.0)
      }
      .listStyle(.sidebar)
      .frame(minWidth: 200, idealWidth: 220)
    } detail: {
      Group {
        switch selectedTab {
        case "Accounts":
          AccountsPreferencesView(vm: vm)
        case "General":
          GeneralPreferencesView(vm: vm)
        case "Advanced":
          AdvancedPreferencesView(vm: vm)
        default:
          AccountsPreferencesView(vm: vm)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .navigationTitle("Preferences")
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Done") {
          dismiss()
        }
      }
    }
    .frame(minWidth: 600, minHeight: 400)
    .enableInjection()
  }
}

struct AccountsPreferencesView: View {
  @ObservedObject var vm: AppViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Calendar Accounts")
        .font(.title2.weight(.medium))
        .padding(.bottom, 8)

      VStack(alignment: .leading, spacing: 16) {
        // Add Account Button
        Button {
          if let window = NSApplication.shared.windows.first {
            vm.addGoogleAccount(presentationAnchor: window)
          }
        } label: {
          Label("Add Google Account", systemImage: "person.crop.circle.badge.plus")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)

        // Connected Accounts
        if !vm.accounts.isEmpty {
          VStack(alignment: .leading, spacing: 12) {
            Text("Connected Accounts")
              .font(.headline)

            ForEach(vm.accounts) { account in
              AccountPreferencesRow(account: account, vm: vm)
            }
          }
        }
      }

      Spacer()
    }
    .padding(24)
  }
}

struct AccountPreferencesRow: View {
  let account: GoogleAccount
  @ObservedObject var vm: AppViewModel
  @State private var isExpanded = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Account Header
      HStack {
        Circle()
          .fill(Color(hex: account.colorHex))
          .frame(width: 12, height: 12)

        Text(account.email)
          .font(.subheadline.weight(.medium))

        Spacer()

        Button {
          vm.removeAccount(email: account.email)
        } label: {
          Image(systemName: "trash")
            .foregroundColor(.red)
        }
        .buttonStyle(.borderless)
      }

      // Account Settings
      VStack(alignment: .leading, spacing: 8) {
        // Auto-join toggle
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text("Auto-join meetings")
              .font(.subheadline)
            Text("Automatically join video calls for this account")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          Spacer()

          Toggle(
            "",
            isOn: Binding(
              get: { account.autoJoinEnabled },
              set: { vm.updateAutoJoin(email: account.email, enabled: $0) }
            )
          )
          .toggleStyle(.switch)
          .labelsHidden()
        }

        // Calendars
        if let calendars = vm.calendarsByAccount[account.email], !calendars.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            Text("Calendars")
              .font(.subheadline.weight(.medium))

            ForEach(calendars) { calendar in
              CalendarPreferencesRow(
                calendar: calendar,
                accountEmail: account.email,
                vm: vm
              )
            }
          }
          .padding(.leading, 16)
        }
      }
    }
    .padding(12)
    .background(Color(NSColor.controlBackgroundColor))
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}

struct CalendarPreferencesRow: View {
  let calendar: GoogleCalendar
  let accountEmail: String
  @ObservedObject var vm: AppViewModel
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

      Text(calendar.summary)
        .font(.subheadline)

      Spacer()

      // Visibility toggle
      Toggle(
        "",
        isOn: Binding(
          get: { calendar.isVisible },
          set: {
            vm.toggleCalendarVisibility(email: accountEmail, calendarId: calendar.id, isVisible: $0)
          }
        )
      )
      .toggleStyle(.switch)
      .labelsHidden()
      .scaleEffect(0.8)
    }
    .padding(.vertical, 4)
  }
}

struct GeneralPreferencesView: View {
  @ObservedObject var vm: AppViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("General Settings")
        .font(.title2.weight(.medium))
        .padding(.bottom, 8)

      VStack(alignment: .leading, spacing: 16) {
        // Default View
        VStack(alignment: .leading, spacing: 8) {
          Text("Default View")
            .font(.subheadline.weight(.medium))

          Picker("Default View", selection: $vm.selectedViewMode) {
            ForEach(AppViewModel.ViewMode.allCases, id: \.self) { mode in
              Text(mode.rawValue).tag(mode)
            }
          }
          .pickerStyle(.segmented)
          .frame(width: 200)
        }

        // Week Style
        if vm.selectedViewMode == .week {
          VStack(alignment: .leading, spacing: 8) {
            Text("Week View Style")
              .font(.subheadline.weight(.medium))

            Picker("Week Style", selection: $vm.selectedWeekStyle) {
              ForEach(AppViewModel.WeekStyle.allCases, id: \.self) { style in
                Text(style.rawValue).tag(style)
              }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
          }
        }
      }

      Spacer()
    }
    .padding(24)
  }
}

struct AdvancedPreferencesView: View {
  @ObservedObject var vm: AppViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Advanced Settings")
        .font(.title2.weight(.medium))
        .padding(.bottom, 8)

      VStack(alignment: .leading, spacing: 16) {
        // Refresh Data
        VStack(alignment: .leading, spacing: 8) {
          Text("Data Management")
            .font(.subheadline.weight(.medium))

          Button("Refresh All Calendars") {
            Task { await vm.refreshAllAccounts() }
          }
          .buttonStyle(.bordered)
          .disabled(vm.isBusy)

          if vm.isBusy {
            ProgressView()
              .scaleEffect(0.8)
          }
        }

        // Clear Data
        VStack(alignment: .leading, spacing: 8) {
          Text("Clear Data")
            .font(.subheadline.weight(.medium))

          Button("Clear All Data") {
            // Clear all stored data
            UserDefaults.standard.removeObject(forKey: "rise.google.accounts")
            UserDefaults.standard.removeObject(forKey: "rise.ui.state")
            // Clear calendar settings
            for account in vm.accounts {
              UserDefaults.standard.removeObject(forKey: "rise.calendar.settings." + account.email)
            }
          }
          .buttonStyle(.bordered)
          .foregroundColor(.red)
        }
      }

      Spacer()
    }
    .padding(24)
  }
}
