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
    .enableInjection()
  }

  #if DEBUG
    @ObserveInjection var forceRedraw
  #endif
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
    .enableInjection()
  }

  #if DEBUG
    @ObserveInjection var forceRedraw
  #endif
}

struct CalendarPreferencesRow: View {
  let calendar: GoogleCalendar
  let accountEmail: String
  @ObservedObject var vm: AppViewModel
  @State private var hexInput: String = ""
  private let presetColors: [String] = [
    "#4285F4", "#DB4437", "#F4B400", "#0F9D58", "#AB47BC",
    "#00ACC1", "#5E6AD2", "#FF7043", "#26A69A", "#8D6E63",
  ]

  var body: some View {
    HStack(spacing: CalendarStyle.spacingMedium) {
      // Color indicator
      Circle()
        .fill(Color(hex: hexInput.isEmpty ? calendar.displayColor : hexInput))
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

      // Preset color options
      HStack(spacing: 6) {
        ForEach(presetColors, id: \.self) { swatch in
          let isSelected =
            (hexInput.isEmpty ? calendar.displayColor.uppercased() : hexInput.uppercased())
            == swatch.uppercased()
          Button {
            hexInput = swatch
            applyColorChange()
          } label: {
            ZStack {
              Circle()
                .fill(Color(hex: swatch))
              if isSelected {
                Image(systemName: "checkmark")
                  .font(.system(size: 8, weight: .bold))
                  .foregroundColor(.white)
              }
            }
            .frame(width: 16, height: 16)
            .overlay(
              Circle()
                .stroke(
                  isSelected ? Color.primary.opacity(0.5) : Color.primary.opacity(0.2), lineWidth: 1
                )
            )
          }
          .buttonStyle(.plain)
          .help(swatch)
        }
      }

      // Hex color editor
      TextField("#RRGGBB", text: $hexInput)
        .onSubmit { applyColorChange() }
        .textFieldStyle(.roundedBorder)
        .font(CalendarStyle.fontCaption)
        .frame(width: 100)
        .disableAutocorrection(true)
        .help("Enter a hex color (e.g. #1A73E8)")

      Button {
        applyColorChange()
      } label: {
        Image(systemName: "checkmark.circle")
      }
      .buttonStyle(.borderless)
      .help("Save color")

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
    .onAppear {
      if hexInput.isEmpty { hexInput = calendar.displayColor }
    }
    .onChange(of: calendar.displayColor) { newColor in
      hexInput = newColor
    }
    .enableInjection()
  }

  private func applyColorChange() {
    let normalized = normalizeHexString(hexInput)
    hexInput = normalized
    vm.updateCalendarColor(email: accountEmail, calendarId: calendar.id, color: normalized)
  }

  private func normalizeHexString(_ input: String) -> String {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
    let noHash = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
    let upper = noHash.uppercased()
    switch upper.count {
    case 3, 6, 8:
      return "#" + upper
    default:
      return calendar.displayColor
    }
  }

  #if DEBUG
    @ObserveInjection var forceRedraw
  #endif
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
    .enableInjection()
  }

  #if DEBUG
    @ObserveInjection var forceRedraw
  #endif
}

struct AdvancedPreferencesView: View {
  @ObservedObject var vm: AppViewModel
  @State private var showResetConfirm = false
  @State private var showClearCacheConfirm = false

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

          HStack(spacing: CalendarStyle.preferencesSpacingMedium) {
            Button {
              vm.syncNow()
            } label: {
              Label("Sync Now", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)

            Button(role: .destructive) {
              showClearCacheConfirm = true
            } label: {
              Label("Clear Local Cache", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .alert("Clear local cache?", isPresented: $showClearCacheConfirm) {
              Button("Cancel", role: .cancel) {}
              Button("Clear", role: .destructive) { vm.clearLocalCache() }
            } message: {
              Text("This removes cached calendars and events. Accounts and tokens remain.")
            }

            Spacer()

            Button(role: .destructive) {
              showResetConfirm = true
            } label: {
              Label("Reset App", systemImage: "exclamationmark.triangle")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .alert("Reset app?", isPresented: $showResetConfirm) {
              Button("Cancel", role: .cancel) {}
              Button("Reset", role: .destructive) { vm.resetApp() }
            } message: {
              Text("This signs you out of all accounts, clears tokens, settings and local data.")
            }
          }
        }
      }

      Spacer()
    }
    .padding(CalendarStyle.preferencesSpacingLarge)
    .enableInjection()
  }

  #if DEBUG
    @ObserveInjection var forceRedraw
  #endif
}
