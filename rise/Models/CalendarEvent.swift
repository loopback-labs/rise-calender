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
