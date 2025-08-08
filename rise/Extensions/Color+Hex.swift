import SwiftUI

extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a: UInt64
    let r: UInt64
    let g: UInt64
    let b: UInt64
    switch hex.count {
    case 3:  // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:  // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:  // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (1, 1, 1, 0)
    }

    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }
}

// MARK: - Responsive Layout Modifiers
extension View {
  func responsiveLayout() -> some View {
    self
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .clipped()
  }
}

// MARK: - Mac Calendar Style System
enum CalendarStyle {
  // Layout dimensions
  static let hourRowHeight: CGFloat = 60
  static let dayColumnMinWidth: CGFloat = 160  // Increased for better readability
  static let dayHeaderHeight: CGFloat = 32  // Increased for better spacing
  static let eventCornerRadius: CGFloat = 4  // Slightly increased for modern look
  static let monthCellCornerRadius: CGFloat = 6
  static let monthCellHeight: CGFloat = 120  // Height for month view cells
  static let monthHeaderHeight: CGFloat = 48  // Height for month header

  // Colors matching Mac Calendar
  static var background: Color { Color(NSColor.windowBackgroundColor) }
  static var panelBackground: Color { Color(NSColor.controlBackgroundColor) }
  static var gridLine: Color { .secondary.opacity(0.15) }  // Slightly more visible
  static var subtleGridFill: Color { .secondary.opacity(0.04) }  // Slightly more visible
  static var nowLine: Color { .red }
  static var todayBackground: Color { Color.accentColor.opacity(0.08) }  // Slightly more visible
  static var monthGridBackground: Color { Color(NSColor.controlBackgroundColor) }
}

extension Date {
  var isToday: Bool { Calendar.current.isDateInToday(self) }
}

struct TodayBadge: View {
  let date: Date
  var body: some View {
    Group {
      if date.isToday {
        Text(date, format: .dateTime.day())
          .font(.caption2.weight(.bold))  // Made bold for better visibility
          .padding(.horizontal, 6)  // Increased padding
          .padding(.vertical, 2)  // Increased padding
          .background(Circle().fill(Color.accentColor))
          .foregroundColor(.white)
      } else {
        Text(date, format: .dateTime.day())
          .font(.caption2.weight(.medium))  // Made medium weight for consistency
          .foregroundColor(.secondary)
      }
    }
  }
}

struct NowIndicator: View {
  let startOfDay: Date
  var body: some View {
    TimelineView(.periodic(from: .now, by: 60)) { _ in
      let minutes = minutesSinceMidnight(Date())
      let y = CGFloat(minutes) / 60.0 * CalendarStyle.hourRowHeight
      Rectangle()
        .fill(CalendarStyle.nowLine)
        .frame(height: 2)  // Increased thickness for better visibility
        .offset(y: y)
        .overlay(
          Circle().fill(CalendarStyle.nowLine).frame(width: 8, height: 8)  // Increased size
            .offset(x: -4, y: y - 4), alignment: .topLeading  // Adjusted offset
        )
    }
  }

  private func minutesSinceMidnight(_ date: Date) -> Int {
    let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
    return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
  }
}
