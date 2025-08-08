import Foundation

enum MeetingLinkDetector {
  static func detect(in text: String?) -> URL? {
    guard let text, !text.isEmpty else { return nil }

    // Ordered by most common first
    let patterns: [String] = [
      #"https?://meet\.google\.com/[A-Za-z0-9\-]+"#,
      #"https?://(www\.)?zoom\.us/j/[A-Za-z0-9\?&=\-]+"#,
      #"https?://([a-zA-Z0-9\-]+)\.zoom\.us/j/[A-Za-z0-9\?&=\-]+"#,
      #"https?://teams\.microsoft\.com/l/meetup-join/[A-Za-z0-9/_\-\?&=\.]+"#,
      #"https?://([a-zA-Z0-9\-]+)\.webex\.com/[A-Za-z0-9/_\-\?&=\.]+"#,
      #"https?://(www\.)?bluejeans\.com/[A-Za-z0-9\-]+"#,
    ]

    for pattern in patterns {
      if let url = firstMatch(pattern: pattern, in: text) { return url }
    }
    return nil
  }

  private static func firstMatch(pattern: String, in text: String) -> URL? {
    do {
      let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
      let range = NSRange(text.startIndex..<text.endIndex, in: text)
      if let match = regex.firstMatch(in: text, options: [], range: range) {
        if let r = Range(match.range, in: text) {
          return URL(string: String(text[r]))
        }
      }
    } catch { return nil }
    return nil
  }
}
