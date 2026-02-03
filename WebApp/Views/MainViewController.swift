import AppKit
import WebKit

@MainActor
final class MainViewController: NSViewController {
    private let webViewManager = WebViewManager()

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        webViewManager.loadHome()
    }

    private func setupWebView() {
        let webView = webViewManager.webView
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func reload() {
        webViewManager.reload()
    }

    func goBack() {
        webViewManager.goBack()
    }

    func goForward() {
        webViewManager.goForward()
    }

    var webView: WKWebView {
        webViewManager.webView
    }
}
