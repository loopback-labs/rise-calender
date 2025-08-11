import AppKit
import Foundation

final class AutoJoinScheduler {
  static let shared = AutoJoinScheduler()
  private init() {}

  private var timer: Timer?
  private var launchedEventIds: Set<String> = []

  func start(getUpcomingEvents: @escaping () -> [CalendarEvent]) {
    timer?.invalidate()
    timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
      self?.check(events: getUpcomingEvents())
    }
    RunLoop.main.add(timer!, forMode: .common)
  }

  func stop() {
    timer?.invalidate()
    timer = nil
  }

  private func check(events: [CalendarEvent]) {
    let now = Date()
    for event in events {
      guard let url = event.meetingURL else { continue }
      // Only join events the user has accepted
      if event.selfResponse != .accepted { continue }
      if launchedEventIds.contains(event.id) { continue }
      // Join if within [-1min, +1min] of the start time
      let delta = event.startDate.timeIntervalSince(now)
      if delta <= 60 && delta >= -60 {
        launchedEventIds.insert(event.id)
        NSWorkspace.shared.open(url)
      }
    }
  }
}
