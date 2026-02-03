# Creating a New App from Template

This document explains how to create a new macOS web app wrapper using this template.

## Step 1: Copy the Project

```bash
cp -r WebApp MyNewApp
cd MyNewApp
```

## Step 2: Rename the Xcode Project

1. Open `WebApp.xcodeproj` in Xcode
2. In the Project Navigator, click on "WebApp" at the top
3. In the File Inspector (right panel), change "Identity and Type > Name" to your app name
4. When prompted, click "Rename" to rename associated items

Or manually:
```bash
mv WebApp.xcodeproj MyNewApp.xcodeproj
# Update project.pbxproj file references as needed
```

## Step 3: Update Configuration

Edit `WebApp/Configuration/Config.swift`:

```swift
enum Config {
    // MARK: - App Identity
    static let appName = "My New App"
    static let bundleIdentifier = "com.yourcompany.mynewapp"

    // MARK: - Web Configuration
    static let homeURL = URL(string: "https://yourwebapp.com")!
    static let allowedDomains: [String] = [
        "yourwebapp.com",
        "api.yourwebapp.com",
        "cdn.yourwebapp.com"
    ]
    static let customUserAgent = "MyNewApp/1.0 (macOS)"

    // MARK: - Window Configuration
    static let windowWidth: CGFloat = 1400  // Adjust as needed
    static let windowHeight: CGFloat = 900
    static let minWindowWidth: CGFloat = 800
    static let minWindowHeight: CGFloat = 600
}
```

## Step 4: Update Bundle Identifier

1. In Xcode, select the project in the navigator
2. Select your target
3. Under "Signing & Capabilities", update the Bundle Identifier
4. Or edit `Info.plist` directly

## Step 5: Add App Icon

1. Open `WebApp/Resources/Assets.xcassets` in Xcode
2. Select `AppIcon`
3. Drag your icon images to the appropriate slots:
   - 16x16 @1x and @2x
   - 32x32 @1x and @2x
   - 128x128 @1x and @2x
   - 256x256 @1x and @2x
   - 512x512 @1x and @2x

Tip: Use a tool like [App Icon Generator](https://appicon.co/) to generate all sizes from a single 1024x1024 image.

## Step 6: Update Info.plist

Edit `WebApp/App/Info.plist` to update:
- `CFBundleName`: Your app's display name
- `CFBundleIdentifier`: Your bundle identifier (or use $(PRODUCT_BUNDLE_IDENTIFIER))
- `CFBundleShortVersionString`: Version number (e.g., "1.0")
- `CFBundleVersion`: Build number (e.g., "1")

## Step 7: Configure Entitlements (Optional)

Edit `WebApp/WebApp.entitlements` to add or remove capabilities:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <!-- App Sandbox (required for Mac App Store) -->
    <key>com.apple.security.app-sandbox</key>
    <true/>

    <!-- Network access -->
    <key>com.apple.security.network.client</key>
    <true/>

    <!-- File access via picker dialogs -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>

    <!-- Add more as needed -->
</dict>
</plist>
```

## Step 8: Customize JavaScript Bridge (Optional)

To add custom native actions, edit `WebApp/WebView/JavaScriptBridge.swift`:

```swift
private func handleAction(_ action: String, payload: [String: Any], requestId: String) {
    switch action {
    // Existing actions...
    case "myCustomAction":
        handleMyCustomAction(payload: payload, requestId: requestId)
    default:
        sendResponse(requestId: requestId, data: ["error": "Unknown action"])
    }
}

private func handleMyCustomAction(payload: [String: Any], requestId: String) {
    // Your custom logic here
    sendResponse(requestId: requestId, data: ["success": true])
}
```

## Step 9: Build and Test

1. Select your target in Xcode
2. Choose a destination (My Mac)
3. Press Cmd+R to build and run
4. Test all functionality:
   - Page loads correctly
   - External links open in browser
   - Menu items work
   - Window state persists after quit/relaunch
   - JavaScript bridge functions work

## Step 10: Prepare for Distribution

### For Direct Distribution:
1. Product > Archive
2. Distribute App > Copy App
3. Notarize with `xcrun notarytool`

### For Mac App Store:
1. Ensure all required entitlements are set
2. Product > Archive
3. Distribute App > App Store Connect

## Common Customizations

### Adding a Loading Indicator

Edit `MainViewController.swift` to add a loading state:

```swift
private var loadingIndicator: NSProgressIndicator?

override func viewDidLoad() {
    super.viewDidLoad()
    setupLoadingIndicator()
    // ...
}

private func setupLoadingIndicator() {
    let indicator = NSProgressIndicator()
    indicator.style = .spinning
    indicator.isIndeterminate = true
    // Position and add to view
    loadingIndicator = indicator
}
```

### Disabling Features

To disable the JavaScript bridge:
- Don't register it in `WebViewManager.init()`

To disable specific domains:
- Remove them from `Config.allowedDomains`

### Custom Error Pages

Edit the `showErrorPage` method in `WebViewManager.swift` to customize the error page HTML.

## Troubleshooting

### "Cannot find 'Config' in scope"
Ensure `Config.swift` is included in the target's Compile Sources.

### WebView shows blank
Check the console for network errors. Verify your URL is accessible and the domain is in `allowedDomains`.

### JavaScript bridge not working
Open Web Inspector (Cmd+Opt+I in debug builds) and check for JavaScript errors.

### Window position not restored
Ensure the window closes normally (not force-quit). Check that UserDefaults access is permitted.
