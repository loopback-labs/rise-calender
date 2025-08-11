import Foundation

struct GoogleCalendar: Codable, Hashable, Identifiable {
  let id: String
  let summary: String
  let backgroundColor: String?
  var isVisible: Bool = true
  var customColor: String?

  var displayColor: String {
    return customColor ?? backgroundColor ?? "#4285F4"
  }
}

enum GoogleCalendarServiceError: Error, LocalizedError {
  case unauthorized
  case requestFailed(status: Int, message: String?)

  var errorDescription: String? {
    switch self {
    case .unauthorized:
      return "Unauthorized (401). Check calendar scope and re-authenticate."
    case let .requestFailed(status, message):
      if let message, !message.isEmpty { return "HTTP \(status): \(message)" }
      return "HTTP \(status) from Google Calendar API"
    }
  }
}

final class GoogleCalendarService {
  static let shared = GoogleCalendarService()
  private init() {}

  func listCalendars(accessToken: String) async throws -> [GoogleCalendar] {
    var request = URLRequest(
      url: URL(string: "https://www.googleapis.com/calendar/v3/users/me/calendarList")!)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    let (data, response) = try await URLSession.shared.data(for: request)
    if let http = response as? HTTPURLResponse, http.statusCode != 200 {
      let body = String(data: data, encoding: .utf8)
      if http.statusCode == 401 { throw GoogleCalendarServiceError.unauthorized }
      throw GoogleCalendarServiceError.requestFailed(status: http.statusCode, message: body)
    }
    let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let items = obj?["items"] as? [[String: Any]] ?? []
    return items.compactMap { dict in
      guard let id = dict["id"] as? String, let summary = dict["summary"] as? String else {
        return nil
      }
      return GoogleCalendar(
        id: id, summary: summary, backgroundColor: dict["backgroundColor"] as? String)
    }
  }

  func listEvents(
    accessToken: String,
    calendarId: String,
    timeMin: Date,
    timeMax: Date,
    selfEmail: String
  ) async throws -> [CalendarEvent] {
    let base = URL(string: "https://www.googleapis.com/calendar/v3/calendars")!
    let eventsURL = base.appendingPathComponent(calendarId).appendingPathComponent("events")
    var comps = URLComponents(url: eventsURL, resolvingAgainstBaseURL: false)!
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime]
    comps.queryItems = [
      URLQueryItem(name: "singleEvents", value: "true"),
      URLQueryItem(name: "orderBy", value: "startTime"),
      URLQueryItem(name: "timeMin", value: iso.string(from: timeMin)),
      URLQueryItem(name: "timeMax", value: iso.string(from: timeMax)),
      // Ensure conferenceData (e.g., Google Meet) is included in responses
      URLQueryItem(name: "conferenceDataVersion", value: "1"),
    ]
    var request = URLRequest(url: comps.url!)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    let (data, response) = try await URLSession.shared.data(for: request)
    if let http = response as? HTTPURLResponse, http.statusCode != 200 {
      let body = String(data: data, encoding: .utf8)
      if http.statusCode == 401 { throw GoogleCalendarServiceError.unauthorized }
      throw GoogleCalendarServiceError.requestFailed(status: http.statusCode, message: body)
    }
    let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let items = obj?["items"] as? [[String: Any]] ?? []
    var results: [CalendarEvent] = []
    for item in items {
      guard let id = item["id"] as? String else { continue }
      let summary = (item["summary"] as? String) ?? "(No title)"
      let start = GoogleCalendarService.parseDate(from: item["start"])
      let end = GoogleCalendarService.parseDate(from: item["end"])
      let location = item["location"] as? String
      let description = item["description"] as? String
      let url =
        GoogleCalendarService.extractMeetingURL(from: item)
        ?? MeetingLinkDetector.detect(
          in: [location, description].compactMap { $0 }.joined(separator: "\n"))
      let calId = calendarId
      let response = GoogleCalendarService.extractSelfResponse(from: item, selfEmail: selfEmail)
      results.append(
        CalendarEvent(
          id: id, calendarId: calId, accountEmail: "", title: summary, startDate: start,
          endDate: end, meetingURL: url, colorHex: nil, location: location,
          description: description,
          selfResponse: response
        ))
    }
    return results
  }

  // Prefer explicit Google API meeting link fields over regex detection
  private static func extractMeetingURL(from item: [String: Any]) -> URL? {
    if let hangout = item["hangoutLink"] as? String, let url = URL(string: hangout) { return url }
    if let conf = item["conferenceData"] as? [String: Any],
      let points = conf["entryPoints"] as? [[String: Any]]
    {
      // Prefer https URLs over sip/tel
      for p in points {
        if let uri = p["uri"] as? String, let url = URL(string: uri),
          ["http", "https"].contains(url.scheme?.lowercased() ?? "")
        {
          return url
        }
      }
      // Fallback: any URI field
      if let any = points.compactMap({ ($0["uri"] as? String).flatMap(URL.init(string:)) }).first {
        return any
      }
    }
    return nil
  }

  private static func parseDate(from value: Any?) -> Date {
    let isoZ = ISO8601DateFormatter()
    isoZ.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let dict = value as? [String: Any] {
      if let dateTime = dict["dateTime"] as? String {
        if let d = isoZ.date(from: dateTime) { return d }
        return ISO8601DateFormatter().date(from: dateTime) ?? Date()
      }
      if let date = dict["date"] as? String {
        var comps = DateComponents()
        let parts = date.split(separator: "-")
        if parts.count == 3 {
          comps.year = Int(parts[0])
          comps.month = Int(parts[1])
          comps.day = Int(parts[2])
          return Calendar.current.date(from: comps) ?? Date()
        }
      }
    }
    return Date()
  }

  private static func extractSelfResponse(from item: [String: Any], selfEmail: String)
    -> AttendeeResponse?
  {
    // Google Calendar event: attendees: [{email, responseStatus}], organizer: {email}
    if let attendees = item["attendees"] as? [[String: Any]] {
      if let me = attendees.first(where: {
        ($0["email"] as? String)?.lowercased() == selfEmail.lowercased()
      }) {
        if let status = me["responseStatus"] as? String {
          return mapGoogleResponse(status)
        }
      }
    }
    // If user is the organizer, some events may omit attendees entry
    if let organizer = item["organizer"] as? [String: Any],
      let orgEmail = organizer["email"] as? String,
      orgEmail.lowercased() == selfEmail.lowercased()
    {
      // Treat organizer as accepted for auto-join purposes unless explicitly declined (rare)
      if let status = organizer["responseStatus"] as? String {
        return mapGoogleResponse(status)
      }
      return .accepted
    }
    return nil
  }

  private static func mapGoogleResponse(_ status: String) -> AttendeeResponse {
    switch status.lowercased() {
    case "accepted": return .accepted
    case "declined": return .declined
    case "tentative": return .tentative
    case "needsaction": return .needsAction
    default: return .unknown
    }
  }
}
