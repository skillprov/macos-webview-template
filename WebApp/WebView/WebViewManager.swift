import AppKit
import WebKit

@MainActor
final class WebViewManager: NSObject {
    let webView: WKWebView
    private var currentURL: URL?
    private var jsBridge: JavaScriptBridge?

    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.isElementFullscreenEnabled = true

        if Config.enableJavaScript {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        }

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = Config.customUserAgent

        super.init()

        jsBridge = JavaScriptBridge(webView: webView)
        jsBridge?.register(in: configuration)

        webView.navigationDelegate = self
        webView.uiDelegate = self

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

    private func isAllowedDomain(_ host: String) -> Bool {
        for domain in Config.allowedDomains {
            if host == domain || host.hasSuffix("." + domain) {
                return true
            }
        }
        return false
    }

    private func openInExternalBrowser(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    private func showErrorPage(title: String, message: String) {
        let isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let bgColor = isDarkMode ? "#1e1e1e" : "#ffffff"
        let textColor = isDarkMode ? "#ffffff" : "#333333"
        let secondaryColor = isDarkMode ? "#aaaaaa" : "#666666"
        let buttonBg = isDarkMode ? "#0066cc" : "#007aff"

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    background: \(bgColor);
                    color: \(textColor);
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    min-height: 100vh;
                    padding: 20px;
                }
                .container {
                    text-align: center;
                    max-width: 400px;
                }
                .icon {
                    font-size: 64px;
                    margin-bottom: 20px;
                }
                h1 {
                    font-size: 24px;
                    font-weight: 600;
                    margin-bottom: 12px;
                }
                p {
                    color: \(secondaryColor);
                    font-size: 16px;
                    line-height: 1.5;
                    margin-bottom: 24px;
                }
                button {
                    background: \(buttonBg);
                    color: white;
                    border: none;
                    padding: 12px 24px;
                    font-size: 16px;
                    border-radius: 8px;
                    cursor: pointer;
                    font-weight: 500;
                }
                button:hover {
                    opacity: 0.9;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="icon">⚠️</div>
                <h1>\(title)</h1>
                <p>\(message)</p>
                <button onclick="location.reload()">Try Again</button>
            </div>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}

extension WebViewManager: WKNavigationDelegate {
    nonisolated func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url,
              let host = url.host else {
            decisionHandler(.allow)
            return
        }

        MainActor.assumeIsolated {
            if isAllowedDomain(host) {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
                openInExternalBrowser(url)
            }
        }
    }

    nonisolated func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        Task { @MainActor in
            handleNavigationError(error)
        }
    }

    nonisolated func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        Task { @MainActor in
            handleNavigationError(error)
        }
    }

    @MainActor
    private func handleNavigationError(_ error: Error) {
        let nsError = error as NSError

        if nsError.code == NSURLErrorCancelled {
            return
        }

        let title: String
        let message: String

        switch nsError.code {
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
            title = "No Internet Connection"
            message = "Please check your network connection and try again."
        case NSURLErrorTimedOut:
            title = "Request Timed Out"
            message = "The server took too long to respond. Please try again."
        case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
            title = "Server Not Found"
            message = "The server could not be reached. Please check the URL and try again."
        case NSURLErrorSecureConnectionFailed:
            title = "Secure Connection Failed"
            message = "A secure connection could not be established."
        default:
            title = "Unable to Load Page"
            message = error.localizedDescription
        }

        showErrorPage(title: title, message: message)
    }
}

extension WebViewManager: WKUIDelegate {
    nonisolated func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url {
            MainActor.assumeIsolated {
                if let host = url.host, isAllowedDomain(host) {
                    webView.load(navigationAction.request)
                } else {
                    openInExternalBrowser(url)
                }
            }
        }
        return nil
    }
}
