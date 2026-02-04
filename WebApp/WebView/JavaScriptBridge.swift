import AppKit
import WebKit
@preconcurrency import UserNotifications
import UniformTypeIdentifiers

@MainActor
final class JavaScriptBridge: NSObject {
    static let handlerName = "native"

    private weak var webView: WKWebView?

    init(webView: WKWebView) {
        self.webView = webView
        super.init()
    }

    func register(in configuration: WKWebViewConfiguration) {
        configuration.userContentController.add(self, name: Self.handlerName)
    }

    private func sendResponse(requestId: String, data: [String: Any]) {
        guard let webView = webView else { return }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }

            let script = """
            if (window.__nativeCallbacks && window.__nativeCallbacks['\(requestId)']) {
                window.__nativeCallbacks['\(requestId)'](\(jsonString));
                delete window.__nativeCallbacks['\(requestId)'];
            }
            """
            webView.evaluateJavaScript(script)
        } catch {
            print("Failed to serialize response: \(error)")
        }
    }

    private func handleAction(_ action: String, payload: [String: Any], requestId: String) {
        switch action {
        case "showNotification":
            handleShowNotification(payload: payload, requestId: requestId)
        case "openFilePicker":
            handleOpenFilePicker(payload: payload, requestId: requestId)
        case "saveFilePicker":
            handleSaveFilePicker(payload: payload, requestId: requestId)
        case "getSystemInfo":
            handleGetSystemInfo(requestId: requestId)
        case "copyToClipboard":
            handleCopyToClipboard(payload: payload, requestId: requestId)
        case "readClipboard":
            handleReadClipboard(requestId: requestId)
        default:
            sendResponse(requestId: requestId, data: ["error": "Unknown action: \(action)"])
        }
    }

    private func handleShowNotification(payload: [String: Any], requestId: String) {
        let title = payload["title"] as? String ?? ""
        let body = payload["body"] as? String ?? ""

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default

                let request = UNNotificationRequest(
                    identifier: UUID().uuidString,
                    content: content,
                    trigger: nil
                )

                center.add(request) { error in
                    Task { @MainActor in
                        if let error = error {
                            self.sendResponse(requestId: requestId, data: ["success": false, "error": error.localizedDescription])
                        } else {
                            self.sendResponse(requestId: requestId, data: ["success": true])
                        }
                    }
                }
            } else {
                Task { @MainActor in
                    self.sendResponse(requestId: requestId, data: ["success": false, "error": "Notification permission denied"])
                }
            }
        }
    }

    private func handleOpenFilePicker(payload: [String: Any], requestId: String) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        if let allowedTypes = payload["allowedTypes"] as? [String] {
            panel.allowedContentTypes = allowedTypes.compactMap { UTType(filenameExtension: $0) }
        }

        panel.begin { response in
            Task { @MainActor in
                if response == .OK, let url = panel.url {
                    self.sendResponse(requestId: requestId, data: [
                        "path": url.path,
                        "name": url.lastPathComponent
                    ])
                } else {
                    self.sendResponse(requestId: requestId, data: ["cancelled": true])
                }
            }
        }
    }

    private func handleSaveFilePicker(payload: [String: Any], requestId: String) {
        let panel = NSSavePanel()

        if let suggestedName = payload["suggestedName"] as? String {
            panel.nameFieldStringValue = suggestedName
        }

        panel.begin { response in
            Task { @MainActor in
                if response == .OK, let url = panel.url {
                    self.sendResponse(requestId: requestId, data: ["path": url.path])
                } else {
                    self.sendResponse(requestId: requestId, data: ["cancelled": true])
                }
            }
        }
    }

    private func handleGetSystemInfo(requestId: String) {
        let appVersion = Config.appVersion
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

        sendResponse(requestId: requestId, data: [
            "appVersion": appVersion,
            "osVersion": osVersion,
            "isDarkMode": isDarkMode
        ])
    }

    private func handleCopyToClipboard(payload: [String: Any], requestId: String) {
        guard let text = payload["text"] as? String else {
            sendResponse(requestId: requestId, data: ["success": false, "error": "No text provided"])
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let success = pasteboard.setString(text, forType: .string)
        sendResponse(requestId: requestId, data: ["success": success])
    }

    private func handleReadClipboard(requestId: String) {
        let pasteboard = NSPasteboard.general
        let text = pasteboard.string(forType: .string) ?? ""
        sendResponse(requestId: requestId, data: ["text": text])
    }
}

extension JavaScriptBridge: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let body = message.body as? [String: Any],
              let action = body["action"] as? String,
              let requestId = body["requestId"] as? String else {
            return
        }

        let payload = body["payload"] as? [String: Any] ?? [:]
        handleAction(action, payload: payload, requestId: requestId)
    }
}
