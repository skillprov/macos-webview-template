import AppKit
import WebKit

@MainActor
final class WebViewManager: NSObject {
    let webView: WKWebView
    private var currentURL: URL?

    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.isElementFullscreenEnabled = true

        if Config.enableJavaScript {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        }

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = Config.customUserAgent

        super.init()

        #if DEBUG
        if Config.enableDevTools {
            webView.isInspectable = true
        }
        #endif

        webView.allowsBackForwardNavigationGestures = true
    }

    func loadHome() {
        loadURL(Config.homeURL)
    }

    func loadURL(_ url: URL) {
        currentURL = url
        let request = URLRequest(url: url)
        webView.load(request)
    }

    func reload() {
        webView.reload()
    }

    func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }

    func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }
}
