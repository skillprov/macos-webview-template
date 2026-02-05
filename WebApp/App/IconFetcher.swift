import AppKit

@MainActor
final class IconFetcher {
    private let cacheDirectory: URL
    private let iconFileName = "app_icon.png"

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        cacheDirectory = appSupport.appendingPathComponent(Config.bundleIdentifier)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private var cachedIconURL: URL {
        cacheDirectory.appendingPathComponent(iconFileName)
    }

    func loadIcon() {
        if let cachedIcon = loadCachedIcon() {
            NSApp.applicationIconImage = cachedIcon
            // Ensure bundle icon is set for Dock persistence
            let bundlePath = Bundle.main.bundlePath
            NSWorkspace.shared.setIcon(cachedIcon, forFile: bundlePath, options: [])
            return
        }

        Task {
            await fetchAndCacheIcon()
        }
    }

    private func loadCachedIcon() -> NSImage? {
        guard FileManager.default.fileExists(atPath: cachedIconURL.path) else {
            return nil
        }
        return NSImage(contentsOf: cachedIconURL)
    }

    private func fetchAndCacheIcon() async {
        guard let host = Config.homeURL.host else {
            print("IconFetcher: No host found")
            return
        }
        let baseURL = "https://\(host)"
        print("IconFetcher: Fetching icon for \(host)")

        // First, try to parse the HTML for high-res icons
        if let iconURL = await findBestIconFromHTML(baseURL: baseURL) {
            print("IconFetcher: Found icon URL from HTML: \(iconURL)")
            if let image = await downloadImage(from: iconURL), image.size.width >= 64 {
                print("IconFetcher: Downloaded icon \(image.size.width)x\(image.size.height)")
                saveToCache(image)
                NSApp.applicationIconImage = image
                return
            }
        }

        // Fallback: try common icon paths
        let fallbackPaths = [
            "\(baseURL)/apple-touch-icon-180x180.png",
            "\(baseURL)/apple-touch-icon-152x152.png",
            "\(baseURL)/apple-touch-icon.png",
            "\(baseURL)/favicon-192x192.png",
            "\(baseURL)/favicon-96x96.png",
            "https://www.google.com/s2/favicons?domain=\(host)&sz=128"
        ]

        for path in fallbackPaths {
            print("IconFetcher: Trying \(path)")
            if let url = URL(string: path),
               let image = await downloadImage(from: url) {
                print("IconFetcher: Got image \(image.size.width)x\(image.size.height)")
                if image.size.width >= 32 {
                    saveToCache(image)
                    NSApp.applicationIconImage = image
                    return
                }
            }
        }

        print("IconFetcher: No icon found")
    }

    private func findBestIconFromHTML(baseURL: String) async -> URL? {
        guard let url = URL(string: baseURL) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else { return nil }

            // Look for apple-touch-icon (highest quality)
            if let iconURL = extractIconURL(from: html, pattern: #"<link[^>]*rel=[\"']apple-touch-icon[\"'][^>]*href=[\"']([^\"']+)[\"']"#, baseURL: baseURL) {
                return iconURL
            }

            // Also try reverse order (href before rel)
            if let iconURL = extractIconURL(from: html, pattern: #"<link[^>]*href=[\"']([^\"']+)[\"'][^>]*rel=[\"']apple-touch-icon[\"']"#, baseURL: baseURL) {
                return iconURL
            }

            // Look for large favicon
            if let iconURL = extractLargestIcon(from: html, baseURL: baseURL) {
                return iconURL
            }

            // Check for web app manifest
            if let manifestURL = extractManifestURL(from: html, baseURL: baseURL),
               let iconURL = await findIconFromManifest(manifestURL) {
                return iconURL
            }

        } catch {
            print("Failed to fetch HTML: \(error)")
        }

        return nil
    }

    private func extractIconURL(from html: String, pattern: String, baseURL: String) -> URL? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }

        let range = NSRange(html.startIndex..., in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: range),
              let urlRange = Range(match.range(at: 1), in: html) else {
            return nil
        }

        let href = String(html[urlRange])
        return resolveURL(href, baseURL: baseURL)
    }

    private func extractLargestIcon(from html: String, baseURL: String) -> URL? {
        let pattern = #"<link[^>]*rel=[\"']icon[\"'][^>]*sizes=[\"'](\d+)x\d+[\"'][^>]*href=[\"']([^\"']+)[\"']"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }

        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: range)

        var bestSize = 0
        var bestURL: URL?

        for match in matches {
            if let sizeRange = Range(match.range(at: 1), in: html),
               let urlRange = Range(match.range(at: 2), in: html) {
                let size = Int(html[sizeRange]) ?? 0
                let href = String(html[urlRange])

                if size > bestSize, let url = resolveURL(href, baseURL: baseURL) {
                    bestSize = size
                    bestURL = url
                }
            }
        }

        return bestURL
    }

    private func extractManifestURL(from html: String, baseURL: String) -> URL? {
        let pattern = #"<link[^>]*rel=[\"']manifest[\"'][^>]*href=[\"']([^\"']+)[\"']"#
        return extractIconURL(from: html, pattern: pattern, baseURL: baseURL)
    }

    private func findIconFromManifest(_ manifestURL: URL) async -> URL? {
        do {
            let (data, _) = try await URLSession.shared.data(from: manifestURL)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let icons = json["icons"] as? [[String: Any]] else {
                return nil
            }

            // Find the largest icon
            var bestSize = 0
            var bestSrc: String?

            for icon in icons {
                if let src = icon["src"] as? String,
                   let sizes = icon["sizes"] as? String {
                    let size = Int(sizes.split(separator: "x").first ?? "0") ?? 0
                    if size > bestSize {
                        bestSize = size
                        bestSrc = src
                    }
                }
            }

            if let src = bestSrc {
                let baseURL = manifestURL.deletingLastPathComponent().absoluteString
                return resolveURL(src, baseURL: baseURL)
            }
        } catch {
            print("Failed to parse manifest: \(error)")
        }

        return nil
    }

    private func resolveURL(_ href: String, baseURL: String) -> URL? {
        if href.hasPrefix("http://") || href.hasPrefix("https://") {
            return URL(string: href)
        } else if href.hasPrefix("//") {
            return URL(string: "https:" + href)
        } else if href.hasPrefix("/") {
            return URL(string: baseURL + href)
        } else {
            return URL(string: baseURL + "/" + href)
        }
    }

    private func downloadImage(from url: URL) async -> NSImage? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("IconFetcher: Not HTTP response for \(url)")
                return nil
            }
            guard httpResponse.statusCode == 200 else {
                print("IconFetcher: HTTP \(httpResponse.statusCode) for \(url)")
                return nil
            }
            guard let image = NSImage(data: data) else {
                print("IconFetcher: Could not create image from data")
                return nil
            }
            return image
        } catch {
            print("IconFetcher: Download error: \(error.localizedDescription)")
            return nil
        }
    }

    private func saveToCache(_ image: NSImage) {
        // Apply macOS-style rounded corners (superellipse)
        let maskedImage = applyMacOSIconMask(to: image)

        guard let tiffData = maskedImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return
        }
        try? pngData.write(to: cachedIconURL)

        // Set icon on app bundle for Dock persistence
        let bundlePath = Bundle.main.bundlePath
        NSWorkspace.shared.setIcon(maskedImage, forFile: bundlePath, options: [])
    }

    private func applyMacOSIconMask(to image: NSImage) -> NSImage {
        let size: CGFloat = 1024  // Standard macOS icon size
        let rect = NSRect(x: 0, y: 0, width: size, height: size)

        let maskedImage = NSImage(size: NSSize(width: size, height: size))
        maskedImage.lockFocus()

        // Create the macOS superellipse (squircle) path
        // macOS uses a continuous curve with ~22.37% corner radius
        let path = createSuperellipsePath(in: rect, cornerRadius: size * 0.2237)
        path.addClip()

        // Draw the original image scaled to fill
        image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)

        maskedImage.unlockFocus()
        return maskedImage
    }

    private func createSuperellipsePath(in rect: NSRect, cornerRadius: CGFloat) -> NSBezierPath {
        // macOS uses a continuous curve (superellipse/squircle), not simple rounded corners
        // This approximates the iOS/macOS icon shape using cubic bezier curves
        let path = NSBezierPath()

        let width = rect.width
        let height = rect.height
        let x = rect.origin.x
        let y = rect.origin.y

        // Control point factor for superellipse approximation
        let k: CGFloat = cornerRadius * 0.552284749831  // Magic number for circle approximation
        let r = cornerRadius

        // Start at top-left, after the corner
        path.move(to: NSPoint(x: x + r, y: y + height))

        // Top edge
        path.line(to: NSPoint(x: x + width - r, y: y + height))

        // Top-right corner (superellipse curve)
        path.curve(to: NSPoint(x: x + width, y: y + height - r),
                   controlPoint1: NSPoint(x: x + width - r + k, y: y + height),
                   controlPoint2: NSPoint(x: x + width, y: y + height - r + k))

        // Right edge
        path.line(to: NSPoint(x: x + width, y: y + r))

        // Bottom-right corner
        path.curve(to: NSPoint(x: x + width - r, y: y),
                   controlPoint1: NSPoint(x: x + width, y: y + r - k),
                   controlPoint2: NSPoint(x: x + width - r + k, y: y))

        // Bottom edge
        path.line(to: NSPoint(x: x + r, y: y))

        // Bottom-left corner
        path.curve(to: NSPoint(x: x, y: y + r),
                   controlPoint1: NSPoint(x: x + r - k, y: y),
                   controlPoint2: NSPoint(x: x, y: y + r - k))

        // Left edge
        path.line(to: NSPoint(x: x, y: y + height - r))

        // Top-left corner
        path.curve(to: NSPoint(x: x + r, y: y + height),
                   controlPoint1: NSPoint(x: x, y: y + height - r + k),
                   controlPoint2: NSPoint(x: x + r - k, y: y + height))

        path.close()
        return path
    }

    func clearCache() {
        try? FileManager.default.removeItem(at: cachedIconURL)
    }
}
