# WebApp

A native macOS WebView wrapper template for creating web app wrappers. Built with Swift 6.0+, AppKit, and WKWebView, targeting macOS 13.0+.

## Features

- **WKWebView Integration**: Modern web content display with JavaScript support
- **Domain Whitelisting**: Control which domains can be loaded in-app; external links open in browser
- **JavaScript Bridge**: Bidirectional communication between web content and native Swift
- **Full Menu Bar**: Standard macOS menus with keyboard shortcuts
- **Window State Persistence**: Remembers window position and size across sessions
- **Network Error Handling**: Friendly error pages with auto-retry on reconnection
- **Dark Mode Support**: Error pages adapt to system appearance
- **Web Inspector**: Debug tools available in development builds

## Requirements

- macOS 13.0+
- Xcode 15.0+
- Swift 6.0+

## Quick Start

1. Open `WebApp.xcodeproj` in Xcode
2. Edit `WebApp/Configuration/Config.swift` to set your app's configuration:
   - `appName`: Your app's display name
   - `homeURL`: The URL to load on launch
   - `allowedDomains`: Domains that can be loaded in-app
3. Build and run (Cmd+R)

## Configuration

All app configuration is centralized in `Config.swift`:

```swift
enum Config {
    // App identity
    static let appName = "MyApp"
    static let bundleIdentifier = "com.example.myapp"

    // Web configuration
    static let homeURL = URL(string: "https://myapp.com")!
    static let allowedDomains = ["myapp.com", "api.myapp.com"]
    static let customUserAgent = "MyApp/1.0 (macOS)"

    // Window settings
    static let windowWidth: CGFloat = 1200
    static let windowHeight: CGFloat = 800
    static let minWindowWidth: CGFloat = 800
    static let minWindowHeight: CGFloat = 600
}
```

## JavaScript Bridge API

The app exposes a native bridge to JavaScript via `window.webkit.messageHandlers.native`.

### Usage Pattern

```javascript
// Helper function for async calls
function callNative(action, payload = {}) {
    return new Promise((resolve) => {
        const requestId = crypto.randomUUID();
        window.__nativeCallbacks = window.__nativeCallbacks || {};
        window.__nativeCallbacks[requestId] = resolve;

        window.webkit.messageHandlers.native.postMessage({
            action,
            payload,
            requestId
        });
    });
}

// Example usage
const result = await callNative('getSystemInfo');
console.log(result); // { appVersion: "1.0", osVersion: "...", isDarkMode: true }
```

### Available Actions

| Action | Payload | Response |
|--------|---------|----------|
| `showNotification` | `{title: string, body: string}` | `{success: boolean, error?: string}` |
| `openFilePicker` | `{allowedTypes?: string[]}` | `{path: string, name: string}` or `{cancelled: true}` |
| `saveFilePicker` | `{suggestedName?: string}` | `{path: string}` or `{cancelled: true}` |
| `getSystemInfo` | `{}` | `{appVersion: string, osVersion: string, isDarkMode: boolean}` |
| `copyToClipboard` | `{text: string}` | `{success: boolean}` |
| `readClipboard` | `{}` | `{text: string}` |

### Examples

```javascript
// Show a notification
await callNative('showNotification', {
    title: 'Download Complete',
    body: 'Your file has been saved.'
});

// Open file picker
const file = await callNative('openFilePicker', {
    allowedTypes: ['pdf', 'txt']
});
if (!file.cancelled) {
    console.log('Selected:', file.path);
}

// Copy to clipboard
await callNative('copyToClipboard', { text: 'Hello, World!' });

// Read clipboard
const { text } = await callNative('readClipboard');

// Get system info
const { appVersion, osVersion, isDarkMode } = await callNative('getSystemInfo');
```

## Menu Bar

The app includes a full macOS menu bar:

| Menu | Items |
|------|-------|
| App | About, Settings, Hide, Quit |
| File | New Window, Close Window |
| Edit | Undo, Redo, Cut, Copy, Paste, Select All |
| View | Reload (Cmd+R), Full Screen (Ctrl+Cmd+F), Dev Tools (Cmd+Opt+I)* |
| Window | Minimize, Zoom, Bring All to Front |
| Help | App Help |

*Dev Tools menu item only appears in Debug builds.

## Building for Release

1. Select the WebApp scheme in Xcode
2. Choose Product > Archive
3. In the Organizer, click "Distribute App"
4. Follow the prompts to sign and export

## Project Structure

```
WebApp/
├── WebApp.xcodeproj/
├── WebApp/
│   ├── App/
│   │   ├── main.swift          # App entry point
│   │   ├── AppDelegate.swift   # App lifecycle
│   │   ├── MenuBuilder.swift   # Menu bar construction
│   │   └── Info.plist          # App metadata
│   ├── Configuration/
│   │   └── Config.swift        # Centralized configuration
│   ├── Views/
│   │   ├── MainViewController.swift
│   │   └── WindowController.swift
│   ├── WebView/
│   │   ├── WebViewManager.swift    # WebView setup & navigation
│   │   └── JavaScriptBridge.swift  # JS ↔ Swift communication
│   ├── Resources/
│   │   └── Assets.xcassets/
│   └── WebApp.entitlements
└── README.md
```

## License

MIT
