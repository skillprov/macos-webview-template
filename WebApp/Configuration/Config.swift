import Foundation

enum Config {
    // MARK: - App Identity
    static let appName = "WebApp"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let bundleIdentifier = "com.example.webapp"

    // MARK: - Web Configuration
    static let homeURL = URL(string: "https://example.com")!
    static let allowedDomains: [String] = [
        "example.com"
    ]
    static let customUserAgent = "WebApp/1.0 (macOS)"

    // MARK: - Window Configuration
    static let windowWidth: CGFloat = 1200
    static let windowHeight: CGFloat = 800
    static let minWindowWidth: CGFloat = 800
    static let minWindowHeight: CGFloat = 600

    // MARK: - Feature Flags
    static let enableJavaScript = true
    static let enableDevTools: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()

    // MARK: - Storage Keys
    enum StorageKeys {
        static let windowFrame = "windowFrame"
    }
}
