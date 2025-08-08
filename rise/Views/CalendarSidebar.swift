import SwiftUI

// Shared layout constants to keep sidebar items perfectly aligned across views
private enum SidebarLayout {
  static let sideInset: CGFloat = 16
  // Account header has a 12pt color dot plus default spacing; indent rows/actions to align text
  static let nestedInset: CGFloat = sideInset + 20
  static let rowHeight: CGFloat = 28
}

struct CalendarSidebar: View {
  @ObservedObject var vm: AppViewModel
  @State private var isAddingAccount = false

  var body: some View {
    VStack(spacing: 0) {
      // Header
      HStack {
        Text("Calendars")
          .font(.headline)
          .foregroundColor(.primary)
        Spacer()
        Button(action: { isAddingAccount = true }) {
          Image(systemName: "plus")
            .foregroundColor(.accentColor)
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, SidebarLayout.sideInset)
      .padding(.vertical, 12)
      .background(Color(NSColor.controlBackgroundColor))

      Divider()

      // Accounts and calendars list
      ScrollView {
        LazyVStack(spacing: 0, pinnedViews: []) {
          ForEach(vm.accounts, id: \.email) { account in
            AccountSection(vm: vm, account: account)
          }
        }
        .padding(.vertical, 8)
      }
    }
    .frame(width: 250)
    .background(Color(NSColor.controlBackgroundColor))
    .sheet(isPresented: $isAddingAccount) {
      AddAccountView(vm: vm)
    }
  }
}

struct AccountSection: View {
  @ObservedObject var vm: AppViewModel
  let account: GoogleAccount
  @State private var isExpanded = true

  var body: some View {
    VStack(spacing: 0) {
      // Account header
      Button(action: { isExpanded.toggle() }) {
        HStack {
          Circle()
            .fill(Color(hex: account.colorHex))
            .frame(width: 12, height: 12)

          Text(account.displayName)
            .font(.subheadline)
            .foregroundColor(.primary)

          Spacer()

          Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .frame(height: SidebarLayout.rowHeight)
        .padding(.horizontal, SidebarLayout.sideInset)
      }
      .buttonStyle(.plain)

      // Calendars list
      if isExpanded {
        VStack(spacing: 0) {
          if let calendars = vm.calendarsByAccount[account.email] {
            ForEach(calendars, id: \.id) { calendar in
              CalendarRow(
                calendar: calendar,
                onToggle: { isVisible in
                  vm.toggleCalendarVisibility(
                    email: account.email,
                    calendarId: calendar.id,
                    isVisible: isVisible
                  )
                }
              )
            }
          }
        }
        .padding(.leading, SidebarLayout.sideInset)
      }

      // Account actions
      HStack {
        Button {
          vm.removeAccount(email: account.email)
        } label: {
          Label("Remove", systemImage: "trash")
            .labelStyle(.titleAndIcon)
        }
        .buttonStyle(.plain)
        .foregroundColor(.red)
        .font(.caption)

        Spacer()

        Toggle(
          "Auto-join",
          isOn: Binding(
            get: { account.autoJoinEnabled },
            set: { newValue in
              if let index = vm.accounts.firstIndex(where: { $0.email == account.email }) {
                vm.accounts[index].autoJoinEnabled = newValue
                // Note: persistAccounts is private, this will be handled by the ViewModel
              }
            }
          )
        )
        .toggleStyle(.switch)
        .scaleEffect(0.8)
      }
      .frame(height: SidebarLayout.rowHeight)
      .padding(.leading, SidebarLayout.sideInset)
      .padding(.trailing, SidebarLayout.sideInset)
      .padding(.vertical, 4)
    }
  }
}

struct CalendarRow: View {
  let calendar: GoogleCalendar
  let onToggle: (Bool) -> Void

  var body: some View {
    HStack {
      Toggle(
        isOn: Binding(
          get: { calendar.isVisible },
          set: { onToggle($0) }
        )
      ) {
        Text(calendar.summary)
          .font(.caption)
          .foregroundColor(.primary)
          .lineLimit(1)
      }
      .toggleStyle(
        ColoredCheckboxStyle(color: Color(hex: calendar.displayColor))
      )
      .scaleEffect(0.9)

      Spacer(minLength: 0)
    }
    .frame(height: SidebarLayout.rowHeight)
    .padding(.vertical, 4)
  }
}

struct AddAccountView: View {
  @ObservedObject var vm: AppViewModel
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 20) {
      Text("Add Google Account")
        .font(.title2)
        .fontWeight(.semibold)

      Text("Sign in with your Google account to access your calendars.")
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)

      Button("Sign in with Google") {
        if let window = NSApp.windows.first {
          vm.addGoogleAccount(presentationAnchor: window)
        }
        dismiss()
      }
      .buttonStyle(.borderedProminent)

      Button("Cancel") {
        dismiss()
      }
      .buttonStyle(.plain)
    }
    .padding()
    .frame(width: 300, height: 200)
  }
}

// MARK: - Colored Checkbox Style
private struct ColoredCheckboxStyle: ToggleStyle {
  let color: Color

  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 8) {
      Button(action: { configuration.isOn.toggle() }) {
        ZStack {
          RoundedRectangle(cornerRadius: 4)
            .stroke(color, lineWidth: 2)
            .background(
              RoundedRectangle(cornerRadius: 4)
                .fill(configuration.isOn ? color.opacity(0.2) : Color.clear)
            )
            .frame(width: 16, height: 16)

          if configuration.isOn {
            Image(systemName: "checkmark")
              .font(.system(size: 10, weight: .bold))
              .foregroundColor(color)
          }
        }
      }
      .buttonStyle(.plain)

      configuration.label
    }
  }
}
