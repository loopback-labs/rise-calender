import AppKit
import SwiftUI

struct AnchoredPopover<Content: View>: NSViewRepresentable {
  @Binding var isPresented: Bool
  let anchorPointInWindow: CGPoint?
  let onClose: (() -> Void)?
  let content: () -> Content

  init(
    isPresented: Binding<Bool>,
    anchorPointInWindow: CGPoint?,
    onClose: (() -> Void)? = nil,
    @ViewBuilder content: @escaping () -> Content
  ) {
    _isPresented = isPresented
    self.anchorPointInWindow = anchorPointInWindow
    self.onClose = onClose
    self.content = content
  }

  func makeNSView(context: Context) -> NSView {
    let view = NSView(frame: .zero)
    context.coordinator.hostingController = NSHostingController(rootView: content())
    return view
  }

  func updateNSView(_ nsView: NSView, context: Context) {
    if isPresented {
      if context.coordinator.popover == nil {
        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        // Initial size; will be updated to fit content below
        popover.contentSize = NSSize(width: 380, height: 320)
        popover.contentViewController = context.coordinator.hostingController
        popover.delegate = context.coordinator
        context.coordinator.popover = popover
      }

      // Update SwiftUI content
      if let hosting = context.coordinator.hostingController {
        hosting.rootView = content()
        hosting.view.layoutSubtreeIfNeeded()

        // Measure and clamp
        let maxWidth: CGFloat = 380
        let maxHeight: CGFloat = 480
        let measured = hosting.view.fittingSize
        let height = min(maxHeight, max(measured.height, 180))
        hosting.view.setFrameSize(NSSize(width: maxWidth, height: height))
        context.coordinator.popover?.contentSize = NSSize(width: maxWidth, height: height)
      }

      if let window = nsView.window, let point = anchorPointInWindow {
        // Convert window coordinate to view coordinate and show popover
        let localPoint = nsView.convert(point, from: nil)
        let rect = NSRect(origin: localPoint, size: .zero)
        context.coordinator.popover?.show(
          relativeTo: rect,
          of: nsView,
          preferredEdge: .maxY
        )
      } else if let screenPoint = anchorPointInWindow,
        let window = NSApplication.shared.windows.first
      {
        // Fallback: if we only have screen coords, convert to window coords for topmost window
        let windowPoint = window.convertPoint(fromScreen: screenPoint)
        let localPoint = nsView.convert(windowPoint, from: nil)
        let rect = NSRect(origin: localPoint, size: .zero)
        context.coordinator.popover?.show(
          relativeTo: rect,
          of: nsView,
          preferredEdge: .maxY
        )
      }
    } else {
      context.coordinator.popover?.performClose(nil)
      context.coordinator.popover = nil
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  final class Coordinator: NSObject, NSPopoverDelegate {
    var parent: AnchoredPopover
    var popover: NSPopover?
    var hostingController: NSHostingController<Content>?

    init(_ parent: AnchoredPopover) {
      self.parent = parent
    }

    func popoverDidClose(_ notification: Notification) {
      parent.onClose?()
    }
  }
}
