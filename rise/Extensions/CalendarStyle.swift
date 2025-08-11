import AppKit
import SwiftUI

// MARK: - Mac Calendar Design System
enum CalendarStyle {
  static let sidebarWidth: CGFloat = 200
  static let preferencesMinWidth: CGFloat = 600
  static let preferencesMinHeight: CGFloat = 400
  static let preferencesSidebarWidth: CGFloat = 220

  // Grid dimensions
  static let hourRowHeight: CGFloat = 60
  static let dayColumnMinWidth: CGFloat = 160
  static let dayHeaderHeight: CGFloat = 32
  static let monthCellHeight: CGFloat = 120

  // Event dimensions
  static let eventCornerRadius: CGFloat = 6

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
  static var gridLine: Color { .secondary.opacity(0.12) }
  static var subtleGridFill: Color { .secondary.opacity(0.03) }
  static var nowLine: Color { .red }
  static var todayBackground: Color { Color.accentColor.opacity(0.06) }
  static var hoverBackground: Color { Color(NSColor.controlBackgroundColor).opacity(0.8) }
  static var eventBorder: Color { .secondary.opacity(0.15) }

  // Typography - More consistent with Mac Calendar
  static let fontCaption: Font = .caption2
  static let fontBody: Font = .body
  static let fontHeadline: Font = .headline
  static let fontTitle: Font = .title2
  static let fontTitleLarge: Font = .title
}

// MARK: - Small utilities
extension Date {
  var isToday: Bool { Calendar.current.isDateInToday(self) }
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
          Circle().fill(CalendarStyle.nowLine)
            .frame(width: CalendarStyle.iconSizeMedium, height: CalendarStyle.iconSizeMedium)
            .offset(x: -4, y: y - 4),
          alignment: .topLeading
        )
    }
  }

  private func minutesSinceMidnight(_ date: Date) -> Int {
    let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
    return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
  }
}
