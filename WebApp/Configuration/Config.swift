import Foundation

enum Config {
    // MARK: - App Identity
    static let appName = "WebApp"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let bundleIdentifier = "com.example.webapp"

    // MARK: - Web Configuration
    static let homeURL = URL(string: "https://www.google.com")!  // Change this to your app's URL
    static let allowedDomains: [String] = [
        "google.com",  // Change these to your app's domains
        "www.google.com",
        "accounts.google.com"
    ]
    static let customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

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
