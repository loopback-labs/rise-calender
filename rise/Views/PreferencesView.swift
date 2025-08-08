import SwiftUI

struct PreferencesView: View {
  @ObserveInjection var inject
  @StateObject var vm: AppViewModel
  @State private var selectedTab = "Accounts"

  private let tabs = [
    ("Accounts", "person.crop.circle"),
    ("General", "gear"),
    ("Advanced", "slider.horizontal.3"),
  ]

  var body: some View {
    HStack(spacing: 0) {
      // Fixed sidebar - non-collapsible
      VStack(spacing: 0) {
        List(tabs, id: \.0, selection: $selectedTab) { tab in
          Label(tab.0, systemImage: tab.1)
            .tag(tab.0)
        }
        .listStyle(.sidebar)
        .frame(width: CalendarStyle.preferencesSidebarWidth)
      }
      .background(CalendarStyle.panelBackground)

      Divider()

      // Detail content area (scrollable)
      ScrollView {
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
        .frame(maxWidth: .infinity, alignment: .topLeading)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .navigationTitle("Preferences")
    .frame(
      minWidth: CalendarStyle.preferencesMinWidth, minHeight: CalendarStyle.preferencesMinHeight
    )
    .enableInjection()
  }
}

struct AccountsPreferencesView: View {
  @ObservedObject var vm: AppViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: CalendarStyle.preferencesSpacingLarge) {
      Text("Calendar Accounts")
        .font(CalendarStyle.fontTitle.weight(.medium))
        .padding(.bottom, CalendarStyle.preferencesSpacingSmall)

      VStack(alignment: .leading, spacing: CalendarStyle.preferencesSpacingLarge) {
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
          VStack(alignment: .leading, spacing: CalendarStyle.preferencesSpacingMedium) {
            Text("Connected Accounts")
              .font(CalendarStyle.fontHeadline)
              .padding(.top, CalendarStyle.preferencesSpacingSmall)

            ForEach(vm.accounts) { account in
              AccountPreferencesRow(account: account, vm: vm)
            }
          }
        }
      }

      Spacer()
    }
    .padding(CalendarStyle.preferencesSpacingLarge)
  }
}

struct AccountPreferencesRow: View {
  let account: GoogleAccount
  @ObservedObject var vm: AppViewModel
  @State private var isExpanded = false

  var body: some View {
    VStack(alignment: .leading, spacing: CalendarStyle.preferencesSpacingMedium) {
      // Account Header
      HStack {
        Circle()
          .fill(Color(hex: account.colorHex))
          .frame(width: CalendarStyle.iconSizeMedium, height: CalendarStyle.iconSizeMedium)

        Text(account.email)
          .font(CalendarStyle.fontBody.weight(.medium))

        Spacer()

        Button(role: .destructive) {
          vm.removeAccount(email: account.email)
        } label: {
          Image(systemName: "trash")
            .foregroundColor(.secondary)
        }
        .buttonStyle(.borderless)
        .help("Remove account")
      }

      // Account Details
      VStack(alignment: .leading, spacing: CalendarStyle.preferencesSpacingMedium) {
        // Auto-join toggle
        HStack(spacing: CalendarStyle.spacingMedium) {
          Image(systemName: "video.fill")
            .foregroundColor(.secondary)
            .font(CalendarStyle.fontCaption)

          VStack(alignment: .leading, spacing: CalendarStyle.spacingSmall) {
            Text("Auto-join meetings")
              .font(CalendarStyle.fontBody.weight(.medium))
              .foregroundColor(.primary)
            Text("Automatically join video calls for this account")
              .font(CalendarStyle.fontCaption)
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

        // Calendars section
        if let calendars = vm.calendarsByAccount[account.email], !calendars.isEmpty {
          VStack(alignment: .leading, spacing: CalendarStyle.preferencesSpacingMedium) {
            Text("Calendars")
              .font(CalendarStyle.fontBody.weight(.medium))
              .padding(.top, CalendarStyle.preferencesSpacingSmall)

            ForEach(calendars) { calendar in
              CalendarPreferencesRow(
                calendar: calendar,
                accountEmail: account.email,
                vm: vm
              )
            }
          }
        }
      }
      .padding(.leading, CalendarStyle.preferencesSpacingLarge)
    }
    .padding(CalendarStyle.preferencesSpacingMedium)
    .background(
      RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
        .fill(CalendarStyle.panelBackground)
        .overlay(
          RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
            .stroke(CalendarStyle.eventBorder, lineWidth: 1)
        )
    )
  }
}

struct CalendarPreferencesRow: View {
  let calendar: GoogleCalendar
  let accountEmail: String
  @ObservedObject var vm: AppViewModel

  var body: some View {
    HStack(spacing: CalendarStyle.spacingMedium) {
      // Color indicator
      Circle()
        .fill(Color(hex: calendar.displayColor))
        .frame(width: CalendarStyle.iconSizeMedium, height: CalendarStyle.iconSizeMedium)
        .overlay(
          Circle()
            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
        )

      // Calendar name
      Text(calendar.summary)
        .font(CalendarStyle.fontBody)
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
      .help(calendar.isVisible ? "Hide calendar" : "Show calendar")
    }
    .padding(.vertical, CalendarStyle.preferencesSpacingSmall)
    .padding(.horizontal, CalendarStyle.preferencesSpacingMedium)
    .background(
      RoundedRectangle(cornerRadius: CalendarStyle.eventCornerRadius)
        .fill(Color.clear)
    )
    .contentShape(Rectangle())
  }
}

struct GeneralPreferencesView: View {
  @ObservedObject var vm: AppViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: CalendarStyle.preferencesSpacingLarge) {
      Text("General Settings")
        .font(CalendarStyle.fontTitle.weight(.medium))
        .padding(.bottom, CalendarStyle.preferencesSpacingSmall)

      Grid(
        horizontalSpacing: CalendarStyle.preferencesSpacingLarge,
        verticalSpacing: CalendarStyle.preferencesSpacingMedium
      ) {
        // Default view
        GridRow {
          Text("Default View")
            .font(CalendarStyle.fontBody.weight(.medium))

          Picker("Default View", selection: $vm.selectedViewMode) {
            ForEach(AppViewModel.ViewMode.allCases, id: \.self) { mode in
              Text(mode.rawValue).tag(mode)
            }
          }
          .pickerStyle(.segmented)
        }

        GridRow {
          EmptyView()
          Text("Choose the default calendar view when the app starts")
            .font(CalendarStyle.fontCaption)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        // Week view style
        GridRow {
          Text("Week View Style")
            .font(CalendarStyle.fontBody.weight(.medium))

          Picker("Week Style", selection: $vm.selectedWeekStyle) {
            ForEach(AppViewModel.WeekStyle.allCases, id: \.self) { style in
              Text(style.rawValue).tag(style)
            }
          }
          .pickerStyle(.segmented)
        }

        GridRow {
          EmptyView()
          Text("Choose the default style for week view")
            .font(CalendarStyle.fontCaption)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      Spacer()
    }
    .padding(CalendarStyle.preferencesSpacingLarge)
  }
}

struct AdvancedPreferencesView: View {
  @ObservedObject var vm: AppViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: CalendarStyle.preferencesSpacingLarge) {
      Text("Advanced Settings")
        .font(CalendarStyle.fontTitle.weight(.medium))
        .padding(.bottom, CalendarStyle.preferencesSpacingSmall)

      VStack(alignment: .leading, spacing: CalendarStyle.preferencesSpacingLarge) {
        // Auto-join settings
        VStack(alignment: .leading, spacing: CalendarStyle.preferencesSpacingMedium) {
          Text("Auto-join Settings")
            .font(CalendarStyle.fontBody.weight(.medium))

          Text(
            "Configure automatic meeting joining behavior for all accounts. You can enable or disable auto-join for individual accounts in the Accounts tab."
          )
          .font(CalendarStyle.fontCaption)
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
        }

        // Sync settings
        VStack(alignment: .leading, spacing: CalendarStyle.preferencesSpacingMedium) {
          Text("Sync Settings")
            .font(CalendarStyle.fontBody.weight(.medium))

          Text(
            "Calendar data is automatically synced every 15 minutes. The app will refresh your calendar data in the background to keep events up to date."
          )
          .font(CalendarStyle.fontCaption)
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
        }

        // Data management
        VStack(alignment: .leading, spacing: CalendarStyle.preferencesSpacingMedium) {
          Text("Data Management")
            .font(CalendarStyle.fontBody.weight(.medium))

          Text(
            "All calendar data is stored locally on your device. OAuth tokens are securely stored in macOS Keychain."
          )
          .font(CalendarStyle.fontCaption)
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
        }
      }

      Spacer()
    }
    .padding(CalendarStyle.preferencesSpacingLarge)
  }
}
