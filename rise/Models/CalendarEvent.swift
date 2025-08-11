import Foundation

struct CalendarEvent: Identifiable, Hashable, Codable {
  let id: String
  let calendarId: String
  let accountEmail: String
  let title: String
  let startDate: Date
  let endDate: Date
  let meetingURL: URL?
  let colorHex: String?
  let location: String?
  let description: String?
  let selfResponse: AttendeeResponse?
}

enum AttendeeResponse: String, Codable, Hashable {
  case accepted
  case declined
  case tentative
  case needsAction
  case unknown
}

// Shared helper to determine if an event is an all-day event (00:00 to 00:00)
extension CalendarEvent {
  var isAllDay: Bool {
    let calendar = Calendar.current
    let start = calendar.dateComponents([.hour, .minute, .second], from: startDate)
    let end = calendar.dateComponents([.hour, .minute, .second], from: endDate)
    return (start.hour == 0 && start.minute == 0 && start.second == 0)
      && (end.hour == 0 && end.minute == 0 && end.second == 0)
  }
}
