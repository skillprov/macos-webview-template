import AppKit
import Network

@MainActor
final class WindowController: NSWindowController {
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private var isOnline = true

    override func windowDidLoad() {
        super.windowDidLoad()
        restoreWindowFrame()
        setupNetworkMonitoring()
    }

    private func restoreWindowFrame() {
        guard let window = window else { return }

        if let frameString = UserDefaults.standard.string(forKey: Config.StorageKeys.windowFrame) {
            let frame = NSRectFromString(frameString)
            if frame.size.width >= Config.minWindowWidth && frame.size.height >= Config.minWindowHeight {
                if NSScreen.screens.contains(where: { $0.frame.intersects(frame) }) {
                    window.setFrame(frame, display: true)
                    return
                }
            }
        }
        window.center()
    }

    private func saveWindowFrame() {
        guard let window = window else { return }
        let frameString = NSStringFromRect(window.frame)
        UserDefaults.standard.set(frameString, forKey: Config.StorageKeys.windowFrame)
    }

    private func setupNetworkMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let wasOnline = self?.isOnline ?? true
                self?.isOnline = path.status == .satisfied

                if let online = self?.isOnline, online && !wasOnline {
                    self?.handleNetworkRestored()
                }
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }

    private func handleNetworkRestored() {
        if let mainVC = contentViewController as? MainViewController {
            mainVC.reload()
        }
    }

    override func close() {
        saveWindowFrame()
        super.close()
    }

    deinit {
        pathMonitor.cancel()
    }
}

extension WindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        saveWindowFrame()
    }

    func windowDidResize(_ notification: Notification) {
        saveWindowFrame()
    }

    func windowDidMove(_ notification: Notification) {
        saveWindowFrame()
    }
}
