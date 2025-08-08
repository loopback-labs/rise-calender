import AuthenticationServices
import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
  @Published var accounts: [GoogleAccount] = []
  @Published var calendarsByAccount: [String: [GoogleCalendar]] = [:]  // email -> calendars
  @Published var events: [CalendarEvent] = []
  @Published var selectedViewMode: ViewMode = .month {
    didSet {
      saveViewState()
      DispatchQueue.main.async { [weak self] in
        self?.adjustWindowSizeForViewMode()
      }
    }
  }
  @Published var selectedWeekStyle: WeekStyle = .grid {
    didSet {
      saveViewState()
      DispatchQueue.main.async { [weak self] in
        self?.adjustWindowSizeForViewMode()
      }
    }
  }
  @Published var selectedDate: Date = Date() { didSet { saveViewState() } }
  @Published var isBusy: Bool = false
  @Published var errorMessage: String?

  enum ViewMode: String, CaseIterable {
    case week = "Week"
    case month = "Month"
  }
  enum WeekStyle: String, CaseIterable {
    case list = "List"
    case grid = "Grid"
  }

  private let tokensKeyPrefix = "google.tokens."  // suffix with email
  private let accountColors = [
    "#4285F4", "#DB4437", "#F4B400", "#0F9D58", "#AB47BC", "#00ACC1",
  ]

  init() {
    loadViewState()
    AutoJoinScheduler.shared.start { [weak self] in
      guard let self else { return [] }
      let enabledEmails = Set(self.accounts.filter { $0.autoJoinEnabled }.map { $0.email })
      return self.upcomingEventsWithin(hours: 1).filter { enabledEmails.contains($0.accountEmail) }
    }
    Task { await refreshAllAccounts() }
  }

  // MARK: - Window Size Management
  private func adjustWindowSizeForViewMode() {
    guard
      let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow || $0.isMainWindow })
    else { return }

    let currentFrame = window.frame
    let minWidth: CGFloat
    let minHeight: CGFloat

    switch selectedViewMode {
    case .month:
      minWidth = 900
      minHeight = 700
    case .week:
      switch selectedWeekStyle {
      case .list:
        minWidth = 700
        minHeight = 600
      case .grid:
        minWidth = 1400
        minHeight = 900
      }
    }

    // Only resize if current window is smaller than minimum
    if currentFrame.width < minWidth || currentFrame.height < minHeight {
      let newWidth = max(currentFrame.width, minWidth)
      let newHeight = max(currentFrame.height, minHeight)
      let newFrame = NSRect(
        x: currentFrame.origin.x,
        y: currentFrame.origin.y,
        width: newWidth,
        height: newHeight
      )

      DispatchQueue.main.async {
        window.setFrame(newFrame, display: true, animate: false)
      }
    }
  }

  func addGoogleAccount(presentationAnchor: ASPresentationAnchor) {
    Task {
      isBusy = true
      defer { isBusy = false }
      do {
        let result = try await GoogleOAuthService.shared.signIn(startingAnchor: presentationAnchor)
        try saveTokens(result.tokens, email: result.email)
        let account = GoogleAccount(
          id: result.email, displayName: result.email, email: result.email, colorHex: nextColor(),
          autoJoinEnabled: true)
        if !accounts.contains(account) {
          accounts.append(account)
          persistAccounts()
        }
        await refreshAccount(email: result.email)
      } catch {
        if let calErr = error as? GoogleCalendarServiceError {
          self.errorMessage = calErr.localizedDescription
        } else {
          self.errorMessage = error.localizedDescription
        }
      }
    }
  }

  func removeAccount(email: String) {
    accounts.removeAll { $0.email == email }
    calendarsByAccount[email] = nil
    try? KeychainStorage.shared.remove(forKey: tokensKeyPrefix + email)
    events.removeAll { $0.accountEmail == email }
    persistAccounts()
  }

  func refreshAllAccounts() async {
    loadAccounts()
    for account in accounts { await refreshAccount(email: account.email) }
  }

  func refreshAccount(email: String) async {
    guard var tokens = try? loadTokens(email: email) else { return }
    do {
      let config = try GoogleOAuthService.shared.loadConfig()
      if tokens.expiryDate < Date() {
        tokens = try await GoogleOAuthService.shared.refreshTokens(
          tokens, clientId: config.clientId)
        try saveTokens(tokens, email: email)
      }

      let calendars = try await GoogleCalendarService.shared.listCalendars(
        accessToken: tokens.accessToken)

      // Load saved calendar settings
      let savedCalendars = loadCalendarSettings(email: email)
      let mergedCalendars = calendars.map { calendar in
        var updatedCalendar = calendar
        if let saved = savedCalendars.first(where: { $0.id == calendar.id }) {
          updatedCalendar.isVisible = saved.isVisible
          updatedCalendar.customColor = saved.customColor
        }
        return updatedCalendar
      }

      calendarsByAccount[email] = mergedCalendars

      let timeMin = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
      let timeMax = Calendar.current.date(byAdding: .day, value: 60, to: Date()) ?? Date()
      var collected: [CalendarEvent] = []
      for calendar in mergedCalendars where calendar.isVisible {
        let evs = try await GoogleCalendarService.shared.listEvents(
          accessToken: tokens.accessToken, calendarId: calendar.id, timeMin: timeMin,
          timeMax: timeMax)
        let colored = evs.map { e in
          CalendarEvent(
            id: e.id + "|" + email, calendarId: e.calendarId, accountEmail: email, title: e.title,
            startDate: e.startDate, endDate: e.endDate, meetingURL: e.meetingURL,
            colorHex: calendar.displayColor, location: e.location, description: e.description)
        }
        collected.append(contentsOf: colored)
      }
      // merge with other accounts
      var others = events.filter { $0.accountEmail != email }
      others.append(contentsOf: collected)
      events = others.sorted { $0.startDate < $1.startDate }
    } catch {
      self.errorMessage = error.localizedDescription
    }
  }

  func upcomingEventsWithin(hours: Int) -> [CalendarEvent] {
    let now = Date()
    let horizon = now.addingTimeInterval(TimeInterval(60 * 60 * hours))
    return events.filter { $0.startDate >= now.addingTimeInterval(-60) && $0.startDate <= horizon }
  }

  // MARK: - Calendar Management
  func toggleCalendarVisibility(email: String, calendarId: String, isVisible: Bool) {
    if var calendars = calendarsByAccount[email] {
      if let index = calendars.firstIndex(where: { $0.id == calendarId }) {
        calendars[index].isVisible = isVisible
        calendarsByAccount[email] = calendars
        saveCalendarSettings(email: email, calendars: calendars)
        Task { await refreshAccount(email: email) }
      }
    }
  }

  func updateCalendarColor(email: String, calendarId: String, color: String) {
    if var calendars = calendarsByAccount[email] {
      if let index = calendars.firstIndex(where: { $0.id == calendarId }) {
        calendars[index].customColor = color
        calendarsByAccount[email] = calendars
        saveCalendarSettings(email: email, calendars: calendars)
        Task { await refreshAccount(email: email) }
      }
    }
  }

  // MARK: - Tokens
  private func saveTokens(_ tokens: OAuthTokens, email: String) throws {
    let data = try JSONEncoder().encode(tokens)
    try KeychainStorage.shared.set(data: data, forKey: tokensKeyPrefix + email)
  }

  private func loadTokens(email: String) throws -> OAuthTokens? {
    guard let data = try KeychainStorage.shared.data(forKey: tokensKeyPrefix + email) else {
      return nil
    }
    return try JSONDecoder().decode(OAuthTokens.self, from: data)
  }

  private func nextColor() -> String {
    let assigned = Set(accounts.map { $0.colorHex })
    return accountColors.first(where: { !assigned.contains($0) }) ?? "#5E6AD2"
  }

  // MARK: - Persistence
  private let accountsPersistenceKey = "rise.google.accounts"
  private let viewStateKey = "rise.ui.state"
  private let calendarSettingsKey = "rise.calendar.settings."  // suffix with email

  private func persistAccounts() {
    do {
      let data = try JSONEncoder().encode(accounts)
      UserDefaults.standard.set(data, forKey: accountsPersistenceKey)
    } catch {
      // ignore persistence errors
    }
  }

  private func loadAccounts() {
    if let data = UserDefaults.standard.data(forKey: accountsPersistenceKey),
      let loaded = try? JSONDecoder().decode([GoogleAccount].self, from: data)
    {
      self.accounts = loaded
    }
  }

  private func saveCalendarSettings(email: String, calendars: [GoogleCalendar]) {
    do {
      let data = try JSONEncoder().encode(calendars)
      UserDefaults.standard.set(data, forKey: calendarSettingsKey + email)
    } catch {
      // ignore persistence errors
    }
  }

  private func loadCalendarSettings(email: String) -> [GoogleCalendar] {
    if let data = UserDefaults.standard.data(forKey: calendarSettingsKey + email),
      let loaded = try? JSONDecoder().decode([GoogleCalendar].self, from: data)
    {
      return loaded
    }
    return []
  }

  // MARK: - UI View State Persistence
  private struct ViewState: Codable {
    let selectedViewMode: String
    let selectedWeekStyle: String
    let selectedDate: Date
  }

  private func loadViewState() {
    guard let data = UserDefaults.standard.data(forKey: viewStateKey),
      let s = try? JSONDecoder().decode(ViewState.self, from: data)
    else { return }
    if let mode = ViewMode(rawValue: s.selectedViewMode) { selectedViewMode = mode }
    if let style = WeekStyle(rawValue: s.selectedWeekStyle) { selectedWeekStyle = style }
    selectedDate = s.selectedDate
  }

  private func saveViewState() {
    let state = ViewState(
      selectedViewMode: selectedViewMode.rawValue,
      selectedWeekStyle: selectedWeekStyle.rawValue,
      selectedDate: selectedDate)
    if let data = try? JSONEncoder().encode(state) {
      UserDefaults.standard.set(data, forKey: viewStateKey)
    }
  }

  // MARK: - Mutations
  func updateAutoJoin(email: String, enabled: Bool) {
    if let idx = accounts.firstIndex(where: { $0.email == email }) {
      accounts[idx].autoJoinEnabled = enabled
      persistAccounts()
    }
  }
}
