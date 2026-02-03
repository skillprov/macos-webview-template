import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private var mainViewController: MainViewController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        createMainWindow()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    private func createMainWindow() {
        let contentRect = NSRect(x: 0, y: 0, width: Config.windowWidth, height: Config.windowHeight)

        window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        mainViewController = MainViewController()
        window?.contentViewController = mainViewController
        window?.title = Config.appName
        window?.minSize = NSSize(width: Config.minWindowWidth, height: Config.minWindowHeight)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }
}
