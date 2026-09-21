#!/usr/bin/env swift

import AppKit
import ApplicationServices
import Darwin

private let chromeBundleID = "com.google.Chrome"
private let promptTitle = "Allow remote debugging?"
private let promptBody = "An external app wants full control over this Chrome session to debug it. This includes access to your saved data, cookies and site data, and the ability to navigate to any URL."
private let promptWarning = "Only web developers should turn on this feature, and only use it with trusted apps."
private let automationBanner = "Chrome is being controlled by automated test software"

private func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
    var result: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name as CFString, &result) == .success else {
        return nil
    }
    return result
}

private func text(_ element: AXUIElement, _ name: String) -> String {
    return attribute(element, name) as? String ?? ""
}

private func elements(_ element: AXUIElement, _ name: String) -> [AXUIElement] {
    return attribute(element, name) as? [AXUIElement] ?? []
}

private func flag(_ element: AXUIElement, _ name: String) -> Bool {
    return attribute(element, name) as? Bool ?? false
}

private func descendants(of root: AXUIElement, limit: Int = 256) -> [AXUIElement] {
    var result: [AXUIElement] = []
    var queue = elements(root, kAXChildrenAttribute)
    while !queue.isEmpty && result.count < limit {
        let element = queue.removeFirst()
        result.append(element)
        queue.append(contentsOf: elements(element, kAXChildrenAttribute))
    }
    return result
}

private func hasExactText(_ element: AXUIElement, _ expected: String) -> Bool {
    return text(element, kAXTitleAttribute) == expected
        || text(element, kAXDescriptionAttribute) == expected
        || text(element, kAXValueAttribute) == expected
}

private struct PromptMatch {
    let app: NSRunningApplication
    let window: AXUIElement
    let sheet: AXUIElement
    let allow: AXUIElement
}

private func matchingPrompt() -> PromptMatch? {
    var matches: [PromptMatch] = []

    for app in NSRunningApplication.runningApplications(withBundleIdentifier: chromeBundleID) {
        let application = AXUIElementCreateApplication(app.processIdentifier)
        for window in elements(application, kAXWindowsAttribute) {
            for sheet in elements(window, kAXChildrenAttribute) {
                guard text(sheet, kAXRoleAttribute) == kAXSheetRole else { continue }

                let sheetChildren = elements(sheet, kAXChildrenAttribute)
                let alertGroups = sheetChildren.filter {
                    text($0, kAXRoleAttribute) == kAXGroupRole
                        && text($0, kAXSubroleAttribute) == "AXApplicationAlertDialog"
                }
                guard alertGroups.count == 1 else { continue }

                let nodes = descendants(of: alertGroups[0])
                guard nodes.contains(where: {
                    text($0, kAXRoleAttribute) == kAXHeadingRole && hasExactText($0, promptTitle)
                }) else { continue }
                guard nodes.contains(where: {
                    text($0, kAXRoleAttribute) == kAXStaticTextRole && hasExactText($0, promptBody)
                }) else { continue }
                guard nodes.contains(where: {
                    text($0, kAXRoleAttribute) == kAXStaticTextRole && hasExactText($0, promptWarning)
                }) else { continue }

                let buttons = nodes.filter { text($0, kAXRoleAttribute) == kAXButtonRole }
                let allow = buttons.filter { hasExactText($0, "Allow") }
                let cancel = buttons.filter { hasExactText($0, "Cancel") }
                let settings = buttons.filter { hasExactText($0, "Turn off in settings") }
                guard allow.count == 1 && cancel.count == 1 && settings.count == 1 else { continue }
                guard flag(allow[0], kAXEnabledAttribute) else { continue }
                matches.append(PromptMatch(app: app, window: window, sheet: sheet, allow: allow[0]))
            }
        }
    }

    return matches.count == 1 ? matches[0] : nil
}

private struct BannerMatch {
    let app: NSRunningApplication
    let window: AXUIElement
    let close: AXUIElement
}

private func nativeDescendants(of root: AXUIElement, limit: Int = 2_048) -> [AXUIElement] {
    var result: [AXUIElement] = []
    var queue = elements(root, kAXChildrenAttribute)
    while !queue.isEmpty && result.count < limit {
        let element = queue.removeFirst()
        if text(element, kAXRoleAttribute) == "AXWebArea" { continue }
        result.append(element)
        queue.append(contentsOf: elements(element, kAXChildrenAttribute))
    }
    return result
}

private func matchingBanners() -> [BannerMatch] {
    var matches: [BannerMatch] = []
    for app in NSRunningApplication.runningApplications(withBundleIdentifier: chromeBundleID) {
        let application = AXUIElementCreateApplication(app.processIdentifier)
        for window in elements(application, kAXWindowsAttribute) {
            let containers = nativeDescendants(of: window).filter {
                text($0, kAXRoleAttribute) == kAXGroupRole
                    && text($0, kAXSubroleAttribute) == "AXApplicationGroup"
                    && text($0, kAXDescriptionAttribute) == "Infobar Container"
            }
            for container in containers {
                let infobars = elements(container, kAXChildrenAttribute).filter {
                    text($0, kAXRoleAttribute) == kAXGroupRole
                        && text($0, kAXSubroleAttribute) == "AXApplicationAlertDialog"
                        && text($0, kAXTitleAttribute) == "Infobar"
                }
                guard infobars.count == 1 else { continue }
                let nodes = descendants(of: infobars[0])
                guard nodes.filter({
                    text($0, kAXRoleAttribute) == kAXStaticTextRole
                        && hasExactText($0, automationBanner)
                }).count == 1 else { continue }
                let buttons = nodes.filter { text($0, kAXRoleAttribute) == kAXButtonRole }
                let settings = buttons.filter { hasExactText($0, "Turn off in settings") }
                let close = buttons.filter { hasExactText($0, "Close") }
                guard settings.count == 1 && close.count == 1 else { continue }
                guard flag(close[0], kAXEnabledAttribute) else { continue }
                matches.append(BannerMatch(app: app, window: window, close: close[0]))
            }
        }
    }
    return matches
}

private func focus(app: NSRunningApplication, window: AXUIElement, element: AXUIElement) {
    _ = app.activate()
    _ = AXUIElementPerformAction(window, kAXRaiseAction as CFString)
    _ = AXUIElementSetAttributeValue(
        window,
        kAXMainAttribute as CFString,
        kCFBooleanTrue,
    )
    _ = AXUIElementSetAttributeValue(
        element,
        kAXFocusedAttribute as CFString,
        kCFBooleanTrue,
    )
    usleep(100_000)
}

private func focus(_ match: PromptMatch) {
    focus(app: match.app, window: match.window, element: match.allow)
}

private func restoreFocus(_ app: NSRunningApplication?, _ chromeWindow: AXUIElement?) {
    if let chromeWindow {
        _ = AXUIElementPerformAction(chromeWindow, kAXRaiseAction as CFString)
        _ = AXUIElementSetAttributeValue(
            chromeWindow,
            kAXMainAttribute as CFString,
            kCFBooleanTrue,
        )
    }
    if let app {
        _ = app.activate()
    }
}

private let mode = CommandLine.arguments.dropFirst().first ?? "probe"
private let timeoutMilliseconds = CommandLine.arguments.dropFirst(2).first.flatMap(Int.init) ?? 0
private let deadline = Date().addingTimeInterval(Double(max(0, timeoutMilliseconds)) / 1_000.0)
private let initialFrontmostApp = NSWorkspace.shared.frontmostApplication
private let initialChromeWindow: AXUIElement? = {
    guard let chrome = NSRunningApplication.runningApplications(withBundleIdentifier: chromeBundleID).first else {
        return nil
    }
    let application = AXUIElementCreateApplication(chrome.processIdentifier)
    return elements(application, kAXWindowsAttribute).first { flag($0, kAXMainAttribute) }
}()
private var totalPresses = 0
private var lastPressAt: Date?
private var previousApp: NSRunningApplication?
private var previousChromeWindow: AXUIElement?
private var observedSheet: AXUIElement?
private var observedSince: Date?

guard AXIsProcessTrusted() else {
    fputs("untrusted\n", stderr)
    exit(3)
}

if mode == "close-banner" {
    var closeCount = 0
    var failed = false
    while closeCount < 8 {
        let matches = matchingBanners()
        guard let match = matches.first else {
            if closeCount > 0 || Date() >= deadline { break }
            usleep(100_000)
            continue
        }
        focus(app: match.app, window: match.window, element: match.close)
        let result = AXUIElementPerformAction(match.close, kAXPressAction as CFString)
        if result != .success {
            failed = true
            break
        }
        closeCount += 1
        usleep(200_000)
    }
    restoreFocus(initialFrontmostApp, initialChromeWindow)
    exit(!failed && matchingBanners().isEmpty ? 0 : 5)
}

if mode == "allow" || mode == "watch" {
    print("READY")
    fflush(stdout)
}

repeat {
    if let match = matchingPrompt() {
        if mode == "probe" {
            print("matched")
            exit(0)
        }
        guard mode == "allow" || mode == "watch" else {
            fputs("unknown-mode\n", stderr)
            exit(64)
        }
        let isNewSheet = observedSheet == nil || !CFEqual(observedSheet!, match.sheet)
        if isNewSheet {
            observedSheet = match.sheet
            observedSince = Date()
            if previousApp == nil {
                previousApp = initialFrontmostApp
                previousChromeWindow = initialChromeWindow
            }
            focus(match)
        }

        let hasDwelled = observedSince.map { Date().timeIntervalSince($0) >= 2.25 } ?? false
        let mayRetry = lastPressAt == nil || Date().timeIntervalSince(lastPressAt!) >= 3.0
        if hasDwelled && mayRetry && totalPresses < 3 {
            focus(match)
            let result = AXUIElementPerformAction(match.allow, kAXPressAction as CFString)
            guard result == .success else {
                restoreFocus(previousApp, previousChromeWindow)
                fputs("press-failed:\(result.rawValue)\n", stderr)
                exit(4)
            }
            totalPresses += 1
            lastPressAt = Date()
        }
    } else {
        observedSheet = nil
        observedSince = nil
        if previousApp != nil {
            restoreFocus(previousApp, previousChromeWindow)
            previousApp = nil
            previousChromeWindow = nil
            lastPressAt = nil
            if mode == "allow" && totalPresses > 0 {
                print("pressed")
                exit(0)
            }
        }
    }
    if Date() >= deadline { break }
    usleep(100_000)
} while true

restoreFocus(previousApp, previousChromeWindow)
if mode == "watch" && totalPresses > 0 {
    exit(0)
}
fputs("not-found\n", stderr)
exit(2)
