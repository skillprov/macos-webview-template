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
        print("Navigation failed: \(error.localizedDescription)")
    }

    nonisolated func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        print("Navigation failed: \(error.localizedDescription)")
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
