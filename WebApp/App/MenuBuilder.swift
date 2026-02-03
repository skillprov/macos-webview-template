import AppKit

@MainActor
final class MenuBuilder {
    private weak var appDelegate: AppDelegate?

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }

    func buildMainMenu() -> NSMenu {
        let mainMenu = NSMenu()

        mainMenu.addItem(buildAppMenu())
        mainMenu.addItem(buildFileMenu())
        mainMenu.addItem(buildEditMenu())
        mainMenu.addItem(buildViewMenu())
        mainMenu.addItem(buildWindowMenu())
        mainMenu.addItem(buildHelpMenu())

        return mainMenu
    }

    private func buildAppMenu() -> NSMenuItem {
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()

        let aboutItem = NSMenuItem(
            title: "About \(Config.appName)",
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )
        appMenu.addItem(aboutItem)

        appMenu.addItem(NSMenuItem.separator())

        let preferencesItem = NSMenuItem(
            title: "Settings...",
            action: nil,
            keyEquivalent: ","
        )
        appMenu.addItem(preferencesItem)

        appMenu.addItem(NSMenuItem.separator())

        let servicesItem = NSMenuItem(title: "Services", action: nil, keyEquivalent: "")
        let servicesMenu = NSMenu(title: "Services")
        servicesItem.submenu = servicesMenu
        NSApp.servicesMenu = servicesMenu
        appMenu.addItem(servicesItem)

        appMenu.addItem(NSMenuItem.separator())

        let hideItem = NSMenuItem(
            title: "Hide \(Config.appName)",
            action: #selector(NSApplication.hide(_:)),
            keyEquivalent: "h"
        )
        appMenu.addItem(hideItem)

        let hideOthersItem = NSMenuItem(
            title: "Hide Others",
            action: #selector(NSApplication.hideOtherApplications(_:)),
            keyEquivalent: "h"
        )
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthersItem)

        let showAllItem = NSMenuItem(
            title: "Show All",
            action: #selector(NSApplication.unhideAllApplications(_:)),
            keyEquivalent: ""
        )
        appMenu.addItem(showAllItem)

        appMenu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Quit \(Config.appName)",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenu.addItem(quitItem)

        appMenuItem.submenu = appMenu
        return appMenuItem
    }

    private func buildFileMenu() -> NSMenuItem {
        let fileMenuItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        let fileMenu = NSMenu(title: "File")

        let newWindowItem = NSMenuItem(
            title: "New Window",
            action: #selector(AppDelegate.newWindow(_:)),
            keyEquivalent: "n"
        )
        fileMenu.addItem(newWindowItem)

        fileMenu.addItem(NSMenuItem.separator())

        let closeItem = NSMenuItem(
            title: "Close Window",
            action: #selector(NSWindow.performClose(_:)),
            keyEquivalent: "w"
        )
        fileMenu.addItem(closeItem)

        fileMenuItem.submenu = fileMenu
        return fileMenuItem
    }

    private func buildEditMenu() -> NSMenuItem {
        let editMenuItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        let editMenu = NSMenu(title: "Edit")

        let undoItem = NSMenuItem(
            title: "Undo",
            action: Selector(("undo:")),
            keyEquivalent: "z"
        )
        editMenu.addItem(undoItem)

        let redoItem = NSMenuItem(
            title: "Redo",
            action: Selector(("redo:")),
            keyEquivalent: "z"
        )
        redoItem.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(redoItem)

        editMenu.addItem(NSMenuItem.separator())

        let cutItem = NSMenuItem(
            title: "Cut",
            action: #selector(NSText.cut(_:)),
            keyEquivalent: "x"
        )
        editMenu.addItem(cutItem)

        let copyItem = NSMenuItem(
            title: "Copy",
            action: #selector(NSText.copy(_:)),
            keyEquivalent: "c"
        )
        editMenu.addItem(copyItem)

        let pasteItem = NSMenuItem(
            title: "Paste",
            action: #selector(NSText.paste(_:)),
            keyEquivalent: "v"
        )
        editMenu.addItem(pasteItem)

        let selectAllItem = NSMenuItem(
            title: "Select All",
            action: #selector(NSText.selectAll(_:)),
            keyEquivalent: "a"
        )
        editMenu.addItem(selectAllItem)

        editMenuItem.submenu = editMenu
        return editMenuItem
    }

    private func buildViewMenu() -> NSMenuItem {
        let viewMenuItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        let viewMenu = NSMenu(title: "View")

        let reloadItem = NSMenuItem(
            title: "Reload Page",
            action: #selector(AppDelegate.reloadPage(_:)),
            keyEquivalent: "r"
        )
        viewMenu.addItem(reloadItem)

        viewMenu.addItem(NSMenuItem.separator())

        let fullScreenItem = NSMenuItem(
            title: "Enter Full Screen",
            action: #selector(NSWindow.toggleFullScreen(_:)),
            keyEquivalent: "f"
        )
        fullScreenItem.keyEquivalentModifierMask = [.command, .control]
        viewMenu.addItem(fullScreenItem)

        #if DEBUG
        if Config.enableDevTools {
            viewMenu.addItem(NSMenuItem.separator())

            let devToolsItem = NSMenuItem(
                title: "Developer Tools",
                action: #selector(AppDelegate.openDevTools(_:)),
                keyEquivalent: "i"
            )
            devToolsItem.keyEquivalentModifierMask = [.command, .option]
            viewMenu.addItem(devToolsItem)
        }
        #endif

        viewMenuItem.submenu = viewMenu
        return viewMenuItem
    }

    private func buildWindowMenu() -> NSMenuItem {
        let windowMenuItem = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
        let windowMenu = NSMenu(title: "Window")

        let minimizeItem = NSMenuItem(
            title: "Minimize",
            action: #selector(NSWindow.performMiniaturize(_:)),
            keyEquivalent: "m"
        )
        windowMenu.addItem(minimizeItem)

        let zoomItem = NSMenuItem(
            title: "Zoom",
            action: #selector(NSWindow.performZoom(_:)),
            keyEquivalent: ""
        )
        windowMenu.addItem(zoomItem)

        windowMenu.addItem(NSMenuItem.separator())

        let bringAllToFrontItem = NSMenuItem(
            title: "Bring All to Front",
            action: #selector(NSApplication.arrangeInFront(_:)),
            keyEquivalent: ""
        )
        windowMenu.addItem(bringAllToFrontItem)

        NSApp.windowsMenu = windowMenu

        windowMenuItem.submenu = windowMenu
        return windowMenuItem
    }

    private func buildHelpMenu() -> NSMenuItem {
        let helpMenuItem = NSMenuItem(title: "Help", action: nil, keyEquivalent: "")
        let helpMenu = NSMenu(title: "Help")

        let appHelpItem = NSMenuItem(
            title: "\(Config.appName) Help",
            action: #selector(NSApplication.showHelp(_:)),
            keyEquivalent: "?"
        )
        helpMenu.addItem(appHelpItem)

        NSApp.helpMenu = helpMenu

        helpMenuItem.submenu = helpMenu
        return helpMenuItem
    }
}
