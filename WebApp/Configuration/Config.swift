import Foundation

enum Config {
    // MARK: - App Identity
    static let appName = "WebApp"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let bundleIdentifier = "com.example.webapp"

    // MARK: - Web Configuration
    static let homeURL = URL(string: "https://www.google.com")!  // Change this to your app's URL
    // Domains that stay within the app (all others open in default browser)
    // The check uses suffix matching: "example.com" also allows "sub.example.com"
    //
    // Tips for configuring:
    // 1. Start with broader domains (e.g., "kth.se") and test the app works
    // 2. Include all domains needed for login/SSO flows
    // 3. Include CDN domains for resources (images, scripts, etc.)
    // 4. To make the app more "contained", remove broad domains - but test
    //    thoroughly as SSO/auth flows often redirect through multiple domains
    static let allowedDomains: [String] = [
        "google.com",              // Main app domain (change this)
        "accounts.google.com"      // Authentication (if needed)
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
