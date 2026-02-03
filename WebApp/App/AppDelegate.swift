import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private var mainViewController: MainViewController?
    private var menuBuilder: MenuBuilder?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenu()
        createMainWindow()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    private func setupMenu() {
        menuBuilder = MenuBuilder(appDelegate: self)
        NSApp.mainMenu = menuBuilder?.buildMainMenu()
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

    @objc func newWindow(_ sender: Any?) {
        createMainWindow()
    }

    @objc func reloadPage(_ sender: Any?) {
        mainViewController?.reload()
    }

    @objc func openDevTools(_ sender: Any?) {
        #if DEBUG
        if let webView = mainViewController?.webView {
            webView.evaluateJavaScript("console.log('Developer Tools opened via menu')")
        }
        #endif
    }
}
