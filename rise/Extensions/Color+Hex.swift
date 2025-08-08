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
      .background(CalendarStyle.background)
  }
}

// MARK: - Accessibility Extensions
extension View {
  func calendarAccessibilityLabel(_ label: String) -> some View {
    self.accessibilityLabel(label)
  }
  
  func calendarAccessibilityHint(_ hint: String) -> some View {
    self.accessibilityHint(hint)
  }
  
  func calendarAccessibilityValue(_ value: String) -> some View {
    self.accessibilityValue(value)
  }
}

// MARK: - Mac Calendar Design System
enum CalendarStyle {
  // MARK: - Layout Dimensions
  static let sidebarWidth: CGFloat = 200  // Mac Calendar sidebar width
  static let detailSidebarWidth: CGFloat = 280  // Mac Calendar detail sidebar width
  static let preferencesMinWidth: CGFloat = 600
  static let preferencesMinHeight: CGFloat = 400
  static let preferencesSidebarWidth: CGFloat = 220

  // Grid dimensions
  static let hourRowHeight: CGFloat = 60
  static let dayColumnMinWidth: CGFloat = 160
  static let dayHeaderHeight: CGFloat = 32
  static let monthCellHeight: CGFloat = 120
  static let monthHeaderHeight: CGFloat = 48

  // Event dimensions
  static let eventCornerRadius: CGFloat = 6
  static let monthCellCornerRadius: CGFloat = 8
  static let eventMinHeight: CGFloat = 20
  static let eventMaxHeight: CGFloat = 24

  // Spacing - Aligned with Mac Calendar
  static let spacingSmall: CGFloat = 4
  static let spacingMedium: CGFloat = 8
  static let spacingLarge: CGFloat = 12
  static let spacingXLarge: CGFloat = 16
  static let spacingXXLarge: CGFloat = 24

  // Tighter spacing for preferences - Mac Calendar style
  static let preferencesSpacingSmall: CGFloat = 6
  static let preferencesSpacingMedium: CGFloat = 10
  static let preferencesSpacingLarge: CGFloat = 16

  // Icon sizes
  static let iconSizeSmall: CGFloat = 8
  static let iconSizeMedium: CGFloat = 12
  static let iconSizeLarge: CGFloat = 16

  // Colors matching Mac Calendar more closely
  static var background: Color { Color(NSColor.windowBackgroundColor) }
  static var panelBackground: Color { Color(NSColor.controlBackgroundColor) }
  static var selectedBackground: Color { Color.accentColor.opacity(0.2) }
  static var gridLine: Color { .secondary.opacity(0.12) }
  static var subtleGridFill: Color { .secondary.opacity(0.03) }
  static var nowLine: Color { .red }
  static var todayBackground: Color { Color.accentColor.opacity(0.06) }
  static var monthGridBackground: Color { Color(NSColor.controlBackgroundColor) }
  static var hoverBackground: Color { Color(NSColor.controlBackgroundColor).opacity(0.8) }
  static var selectionBackground: Color { Color.accentColor.opacity(0.08) }
  static var eventBackground: Color { Color(NSColor.controlBackgroundColor) }
  static var eventBorder: Color { .secondary.opacity(0.15) }

  // Typography - More consistent with Mac Calendar
  static let fontCaption: Font = .caption2
  static let fontBody: Font = .body
  static let fontHeadline: Font = .headline
  static let fontTitle: Font = .title2
  static let fontTitleLarge: Font = .title
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
          .font(CalendarStyle.fontCaption.weight(.bold))
          .padding(.horizontal, CalendarStyle.spacingMedium)
          .padding(.vertical, CalendarStyle.spacingSmall)
          .background(Circle().fill(Color.accentColor))
          .foregroundColor(.white)
      } else {
        Text(date, format: .dateTime.day())
          .font(CalendarStyle.fontCaption.weight(.medium))
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
        .frame(height: 2)
        .offset(y: y)
        .overlay(
          Circle().fill(CalendarStyle.nowLine).frame(
            width: CalendarStyle.iconSizeMedium, height: CalendarStyle.iconSizeMedium
          )
          .offset(x: -4, y: y - 4), alignment: .topLeading
        )
    }
  }

  private func minutesSinceMidnight(_ date: Date) -> Int {
    let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
    return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
  }
}
